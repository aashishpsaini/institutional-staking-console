# frozen_string_literal: true

class RewardEvent < ApplicationRecord
  belongs_to :organization
  belongs_to :network

  validates :reward_date, presence: true
  validates :amount, format: { with: AmountMath::INTEGER_STRING, message: "must be a non-negative integer string" }
  validates :external_id, presence: true, uniqueness: { scope: :organization_id }

  scope :for_network, ->(network) { where(network: network) }
  scope :starting_from, ->(date) { where(reward_date: date..) if date }
  scope :ending_at, ->(date) { where(reward_date: ..date) if date }

  # One row per (network, day), newest day first. Amounts are summed in Ruby —
  # see AmountMath for why SQL SUM() isn't safe for wei-sized values on SQLite.
  def self.daily_rollup
    joins(:network)
      .pluck("networks.slug", :reward_date, :amount)
      .group_by { |slug, date, _amount| [ slug, date ] }
      .map { |(slug, date), rows| { network: slug, date: date.iso8601, amount: AmountMath.sum(rows.map(&:last)), event_count: rows.size } }
      .sort_by { [ -Date.iso8601(_1[:date]).jd, _1[:network] ] }
  end
end
