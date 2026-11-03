# frozen_string_literal: true

# Read model for GET /portfolio. Computed on read from validators (staked balance)
# and reward events (rewards received) — no denormalized totals to keep in sync.
# Uses a fixed number of grouped queries regardless of how many networks exist.
class Portfolio
  Position = Data.define(:network, :balance, :total_rewards_received, :validator_count, :started_at, :updated_at)

  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def positions
    balances = AmountMath.sum_by(organization.validators.pluck(:network_id, :balance))
    rewards = AmountMath.sum_by(organization.reward_events.pluck(:network_id, :amount))
    by_network = organization.validators.group(:network_id)
    counts, started, updated = by_network.count, by_network.minimum(:created_at), by_network.maximum(:updated_at)

    Network.ordered.map do |network|
      Position.new(
        network: network,
        balance: balances.fetch(network.id, "0"),
        total_rewards_received: rewards.fetch(network.id, "0"),
        validator_count: counts.fetch(network.id, 0),
        started_at: started[network.id],
        updated_at: updated[network.id]
      )
    end
  end

  def last_synced_at
    organization.last_rewards_synced_at
  end
end
