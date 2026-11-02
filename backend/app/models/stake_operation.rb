# frozen_string_literal: true

class StakeOperation < ApplicationRecord
  ACTIONS = %w[ stake unstake ].freeze
  STATUSES = %w[ pending submitted confirmed failed ].freeze

  belongs_to :organization
  belongs_to :network

  validates :action, inclusion: { in: ACTIONS }
  validates :status, inclusion: { in: STATUSES }
  validates :amount, presence: true

  def submit_to_chain!
    result = ChainClients::MockChainClient.new.submit_stake(self)
    update! external_id: result[:external_id], status: result[:status]
  end

  def serialize
    {
      id: id,
      network: network.slug,
      action: action,
      amount: amount,
      status: status,
      external_id: external_id,
      error_message: error_message,
      created_at: created_at.iso8601
    }
  end
end
