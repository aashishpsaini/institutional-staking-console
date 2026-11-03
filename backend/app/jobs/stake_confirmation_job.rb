# frozen_string_literal: true

# Polls the chain boundary for a submitted operation's final status and moves it
# to confirmed/failed. Re-enqueues itself while the chain still reports it as
# in flight, up to MAX_ATTEMPTS.
class StakeConfirmationJob < ApplicationJob
  POLL_INTERVAL = 5.seconds
  MAX_ATTEMPTS = 20

  queue_as :default

  retry_on ChainClients::UnavailableError, wait: :polynomially_longer, attempts: 5

  def perform(stake_operation_id, attempt = 1)
    operation = StakeOperation.find_by(id: stake_operation_id)
    return unless operation&.submitted?

    status = ChainClients.current.fetch_operation_status(operation.external_id)

    operation.with_lock do
      operation.update!(status: status) if operation.submitted? && %w[ confirmed failed ].include?(status)
    end

    requeue(operation, attempt) if operation.submitted?
  end

  private
    def requeue(operation, attempt)
      if attempt < MAX_ATTEMPTS
        self.class.set(wait: POLL_INTERVAL).perform_later(operation.id, attempt + 1)
      else
        operation.update!(status: "failed", error_message: "Not confirmed after #{MAX_ATTEMPTS} checks")
      end
    end
end
