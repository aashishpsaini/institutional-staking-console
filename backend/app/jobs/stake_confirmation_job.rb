# frozen_string_literal: true

class StakeConfirmationJob < ApplicationJob
  queue_as :default

  def perform(stake_operation_id)
    operation = StakeOperation.find(stake_operation_id)
    operation.update! status: "confirmed" if operation.status == "submitted"
  end
end
