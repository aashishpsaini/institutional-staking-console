# frozen_string_literal: true

module StakeOperations
  # Creates a stake/unstake request, submits it through the chain boundary and
  # schedules confirmation polling.
  #
  # With an Idempotency-Key, a retried request returns the original operation
  # instead of creating (and submitting) a duplicate.
  class Request
    class IdempotencyConflict < StandardError; end

    Result = Data.define(:operation, :created)

    def self.call(...) = new(...).call

    def initialize(organization:, network:, action:, amount:, idempotency_key: nil)
      @organization = organization
      @attributes = { network: network, action: action, amount: amount }
      @idempotency_key = idempotency_key.presence
    end

    def call
      replay || create_and_submit
    rescue ActiveRecord::RecordNotUnique
      # Lost a race with a concurrent request carrying the same key.
      replay || raise
    end

    private
      attr_reader :organization, :attributes, :idempotency_key

      def replay
        return unless idempotency_key

        existing = organization.stake_operations.find_by(idempotency_key: idempotency_key)
        return unless existing
        raise IdempotencyConflict unless existing.same_request?(**attributes)

        Result.new(operation: existing, created: false)
      end

      def create_and_submit
        operation = organization.stake_operations.create!(**attributes, idempotency_key: idempotency_key)
        operation.submit_to_chain!
        StakeConfirmationJob.set(wait: StakeConfirmationJob::POLL_INTERVAL).perform_later(operation.id) if operation.submitted?

        Result.new(operation: operation, created: true)
      end
  end
end
