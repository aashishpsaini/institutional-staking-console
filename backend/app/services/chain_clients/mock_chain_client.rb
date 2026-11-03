# frozen_string_literal: true

module ChainClients
  # Deterministic mock adapter — swap for real SDK integrations in production.
  #
  # Rewards are derived from each validator's balance and a per-network APR, so the
  # same (validator, day) always yields the same amount and external id regardless
  # of which date window is requested. That property is what makes re-syncs safe.
  class MockChainClient < Base
    APR_BASIS_POINTS = { "ethereum" => 320, "solana" => 700 }.freeze
    DAYS_PER_YEAR = 365

    def fetch_balances(organization)
      organization.validators.includes(:network).map do |validator|
        { network: validator.network.slug, validator_ref: validator.external_ref, balance: validator.balance }
      end
    end

    def fetch_rewards(organization, from:, to:)
      validators = organization.validators.includes(:network).to_a

      (from.to_date..to.to_date).flat_map do |day|
        validators.map { reward_row(_1, day) }
      end
    end

    def submit_stake(operation)
      { external_id: "mock-#{operation.action}-#{SecureRandom.hex(8)}", status: "submitted" }
    end

    def fetch_operation_status(_external_id)
      "confirmed"
    end

    private
      def reward_row(validator, day)
        slug = validator.network.slug

        {
          network: slug,
          date: day,
          amount: daily_reward(validator.balance.to_i, slug, day).to_s,
          validator_ref: validator.external_ref,
          external_id: "#{slug}:#{validator.external_ref}:#{day.iso8601}"
        }
      end

      # balance × APR / 365, with a small deterministic per-day wobble (±2%).
      # Pure integer math — never floats for token amounts.
      def daily_reward(balance, slug, day)
        wobble_percent = 98 + (day.jd % 5)
        balance * APR_BASIS_POINTS.fetch(slug, 0) * wobble_percent / (10_000 * DAYS_PER_YEAR * 100)
      end
  end
end
