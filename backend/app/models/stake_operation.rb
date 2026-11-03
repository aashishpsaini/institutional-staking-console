# frozen_string_literal: true

class StakeOperation < ApplicationRecord
  ACTIONS = %w[ stake unstake ].freeze
  STATUSES = %w[ pending submitted confirmed failed ].freeze
  IN_FLIGHT_STATUSES = %w[ pending submitted ].freeze
  TRANSITIONS = {
    "pending" => %w[ submitted failed ],
    "submitted" => %w[ confirmed failed ],
    "confirmed" => [],
    "failed" => []
  }.freeze

  belongs_to :organization
  belongs_to :network

  validates :action, inclusion: { in: ACTIONS, message: "must be one of: #{ACTIONS.join(', ')}" }
  validates :status, inclusion: { in: STATUSES }
  validates :amount, format: { with: /\A[1-9]\d*\z/, message: "must be a positive integer string in base units" }
  validates :idempotency_key, length: { maximum: 255 }, uniqueness: { scope: :organization_id }, allow_nil: true
  validate :unstake_within_staked_balance, on: :create
  validate :status_transition_allowed, on: :update, if: :will_save_change_to_status?

  scope :recent, -> { order(created_at: :desc, id: :desc) }
  scope :in_flight, -> { where(status: IN_FLIGHT_STATUSES) }

  STATUSES.each do |status|
    define_method(:"#{status}?") { self.status == status }
  end

  def submit_to_chain!(client: ChainClients.current)
    result = client.submit_stake(self)
    update!(external_id: result.fetch(:external_id), status: result.fetch(:status))
  rescue ChainClients::Error => e
    update!(status: "failed", error_message: e.message)
  end

  # True when a replayed request (same Idempotency-Key) carries the same payload.
  def same_request?(network:, action:, amount:)
    network_id == network&.id && self.action == action && self.amount == amount
  end

  private
    def unstake_within_staked_balance
      return unless action == "unstake" && network && organization && amount.to_s.match?(/\A\d+\z/)

      staked = organization.staked_balance_for(network).to_i
      errors.add(:amount, "exceeds staked balance of #{staked}") if amount.to_i > staked
    end

    def status_transition_allowed
      from, to = status_change_to_be_saved
      errors.add(:status, "cannot transition from #{from} to #{to}") unless TRANSITIONS.fetch(from, []).include?(to)
    end
end
