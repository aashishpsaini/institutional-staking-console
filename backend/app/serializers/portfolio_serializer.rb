# frozen_string_literal: true

module PortfolioSerializer
  module_function

  def call(portfolio)
    {
      data: portfolio.positions.map { position(_1) },
      meta: { last_synced_at: portfolio.last_synced_at&.iso8601 }
    }
  end

  def position(position)
    {
      network: position.network.slug,
      network_details: NetworkSerializer.call(position.network),
      balance: position.balance,
      total_rewards_received: position.total_rewards_received,
      validator_count: position.validator_count,
      started_at: position.started_at&.iso8601,
      updated_at: position.updated_at&.iso8601
    }
  end
end
