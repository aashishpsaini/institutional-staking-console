# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :api_keys, dependent: :destroy
  has_many :validators, dependent: :destroy
  has_many :reward_events, dependent: :destroy
  has_many :stake_operations, dependent: :destroy
  has_many :sync_runs, dependent: :destroy

  validates :name, presence: true

  def staked_balance_for(network)
    AmountMath.sum(validators.for_network(network).pluck(:balance))
  end

  def total_rewards_for(network)
    AmountMath.sum(reward_events.for_network(network).pluck(:amount))
  end

  def last_rewards_synced_at
    sync_runs.latest_completed(:rewards)&.finished_at
  end
end
