# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :api_keys, dependent: :destroy
  has_many :validators, dependent: :destroy
  has_many :reward_events, dependent: :destroy
  has_many :stake_operations, dependent: :destroy
  has_many :sync_runs, dependent: :destroy

  def staked_balance_for(network)
    validators.for_network(network).sum { _1.balance.to_i }.to_s
  end

  def total_rewards_for(network)
    reward_events.for_network(network).sum { _1.amount.to_i }.to_s
  end
end
