# frozen_string_literal: true

class SyncRewardsJob < ApplicationJob
  queue_as :default

  def perform(organization_id, from: 7.days.ago.to_date, to: Date.today)
    organization = Organization.find(organization_id)
    client = ChainClients::MockChainClient.new

    sync_run = organization.sync_runs.create!(kind: "rewards", status: "running")

    begin
      rows = client.fetch_rewards(organization, from: from, to: to)
      inserted = 0

      rows.each do |row|
        network = Network.find_by!(slug: row[:network])

        # Idempotent upsert — external_id has a unique index
        event = RewardEvent.find_or_initialize_by(external_id: row[:external_id])
        next if event.persisted?

        event.assign_attributes(
          organization: organization,
          network: network,
          validator_ref: row[:validator_ref],
          reward_date: row[:date],
          amount: row[:amount].to_s
        )
        event.save!
        inserted += 1
      end

      sync_run.update!(status: "completed", finished_at: Time.current)
      Rails.logger.info("[SyncRewardsJob] org=#{organization.id} fetched=#{rows.size} inserted=#{inserted}")
    rescue => e
      sync_run.update!(status: "failed", finished_at: Time.current)
      Rails.logger.error("[SyncRewardsJob] org=#{organization.id} error=#{e.message}")
      raise
    end
  end
end
