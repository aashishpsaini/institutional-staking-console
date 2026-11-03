# frozen_string_literal: true

module StakeOperationSerializer
  module_function

  def call(operation)
    {
      id: operation.id,
      network: operation.network.slug,
      action: operation.action,
      amount: operation.amount,
      status: operation.status,
      external_id: operation.external_id,
      error_message: operation.error_message,
      created_at: operation.created_at.iso8601,
      updated_at: operation.updated_at.iso8601
    }
  end
end
