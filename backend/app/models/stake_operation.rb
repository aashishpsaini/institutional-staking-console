# frozen_string_literal: true

class StakeOperation < ApplicationRecord
  ACTIONS = %w[stake unstake].freeze
  STATUSES = %w[pending submitted confirmed failed].freeze

  belongs_to :organization
  belongs_to :network

  validates :action, inclusion: { in: ACTIONS }
  validates :status, inclusion: { in: STATUSES }
  validates :amount, presence: true
end
