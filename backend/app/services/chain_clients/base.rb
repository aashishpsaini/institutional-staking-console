# frozen_string_literal: true

module ChainClients
  # Contract every chain adapter must fulfil. All amounts are integer strings
  # in the network's base unit (wei, lamports, …).
  class Base
    # -> [{ network:, validator_ref:, balance: }]
    def fetch_balances(organization)
      raise NotImplementedError
    end

    # -> [{ network:, date:, amount:, validator_ref:, external_id: }]
    # `external_id` must be stable for the same reward so re-syncs are idempotent.
    def fetch_rewards(organization, from:, to:)
      raise NotImplementedError
    end

    # -> { external_id:, status: "submitted" }
    def submit_stake(operation)
      raise NotImplementedError
    end

    # -> "submitted" | "confirmed" | "failed"
    def fetch_operation_status(external_id)
      raise NotImplementedError
    end
  end
end
