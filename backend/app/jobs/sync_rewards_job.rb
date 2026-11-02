# frozen_string_literal: true

class SyncRewardsJob < ApplicationJob
  queue_as :default

  def perform(organization_id, from: 7.days.ago.to_date, to: Date.today)
    organization = Organization.find(organization_id)
    sync_run = organization.sync_runs.create!(kind: "rewards", status: "running")

    ingest_rewards(organization, from: from, to: to)
    sync_run.update! status: "completed", finished_at: Time.current
  rescue => e
    sync_run&.update status: "failed", finished_at: Time.current
    raise
  end

  private
    def ingest_rewards(organization, from:, to:)
      client = ChainClients::MockChainClient.new

      client.fetch_rewards(organization, from: from, to: to).each do |row|
        upsert_reward(organization, row)
      end
    end

    def upsert_reward(organization, row)
      event = RewardEvent.find_or_initialize_by(external_id: row[:external_id])
      return if event.persisted?

      event.update!(
        organization: organization,
        network: Network.find_by!(slug: row[:network]),
        validator_ref: row[:validator_ref],
        reward_date: row[:date],
        amount: row[:amount].to_s
      )
    end
end
