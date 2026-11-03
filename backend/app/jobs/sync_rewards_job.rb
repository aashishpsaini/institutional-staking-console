# frozen_string_literal: true

# Pulls reward rows from the chain boundary and upserts them keyed on
# (organization_id, external_id). Re-running any window — overlapping or not —
# converges to the same rows, so totals are never double-counted.
class SyncRewardsJob < ApplicationJob
  BATCH_SIZE = 1_000

  queue_as :default

  retry_on ChainClients::UnavailableError, wait: :polynomially_longer, attempts: 5 do |job, error|
    SyncRun.find_by(id: job.arguments.first)&.fail!(error)
  end

  def perform(sync_run_id)
    sync_run = SyncRun.find(sync_run_id)
    sync_run.start!

    count = ingest(sync_run)
    sync_run.complete!(records_upserted: count)
  rescue ChainClients::UnavailableError
    raise # handled by retry_on
  rescue StandardError => e
    sync_run&.fail!(e)
    raise
  end

  private
    def ingest(sync_run)
      organization = sync_run.organization
      rows = ChainClients.current.fetch_rewards(organization, from: sync_run.from_date, to: sync_run.to_date)
      network_ids = Network.pluck(:slug, :id).to_h

      records = rows.map { build_record(organization, network_ids, _1) }
      records.each_slice(BATCH_SIZE) do |batch|
        RewardEvent.upsert_all(batch, unique_by: %i[ organization_id external_id ],
                                      update_only: %i[ network_id validator_ref reward_date amount ])
      end
      records.size
    end

    # upsert_all bypasses model validations, so adapter output is checked here.
    def build_record(organization, network_ids, row)
      amount = row.fetch(:amount).to_s
      raise ChainClients::Error, "Malformed reward amount #{amount.inspect}" unless amount.match?(AmountMath::INTEGER_STRING)

      {
        organization_id: organization.id,
        network_id: network_ids.fetch(row.fetch(:network)) { raise ChainClients::Error, "Unknown network #{row[:network].inspect}" },
        validator_ref: row[:validator_ref],
        reward_date: row.fetch(:date).to_date,
        amount: amount,
        external_id: row.fetch(:external_id)
      }
    end
end
