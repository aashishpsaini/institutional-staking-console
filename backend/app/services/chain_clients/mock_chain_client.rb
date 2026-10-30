# frozen_string_literal: true

module ChainClients
  class MockChainClient
    # Deterministic mock adapter — swap for real SDK integrations in production.

    def fetch_balances(organization)
      organization.validators.includes(:network).map do |v|
        {
          network: v.network.slug,
          balance: v.balance,
          validator_ref: v.external_ref
        }
      end
    end

    def fetch_rewards(organization, from:, to:)
      # Returns a stable set of reward rows for demo sync.
      eth = Network.find_by!(slug: "ethereum")
      sol = Network.find_by!(slug: "solana")
      days = (from.to_date..to.to_date).to_a
      rows = []
      days.each_with_index do |day, idx|
        rows << {
          network: eth.slug,
          date: day,
          amount: (10_000_000 + idx * 1_000).to_s, # 1e-11 ETH scale toy units as integer strings
          validator_ref: organization.validators.find_by(network: eth)&.external_ref,
          external_id: "eth-#{organization.id}-#{day}"
        }
        rows << {
          network: sol.slug,
          date: day,
          amount: (5_000_000 + idx * 500).to_s,
          validator_ref: organization.validators.find_by(network: sol)&.external_ref,
          external_id: "sol-#{organization.id}-#{day}"
        }
      end
      rows
    end

    def submit_stake(operation)
      {
        external_id: "mock-#{operation.action}-#{SecureRandom.hex(4)}",
        status: "submitted"
      }
    end
  end
end
