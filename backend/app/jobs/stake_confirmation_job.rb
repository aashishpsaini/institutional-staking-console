# frozen_string_literal: true

class StakeConfirmationJob < ApplicationJob
  queue_as :default

  def perform(stake_operation_id)
    op = StakeOperation.find(stake_operation_id)
    return unless op.status == "submitted"

    op.update!(status: "confirmed")
  end
end
