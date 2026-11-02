# frozen_string_literal: true

class RewardEvent < ApplicationRecord
  belongs_to :organization
  belongs_to :network

  validates :reward_date, presence: true
  validates :amount, presence: true
  validates :external_id, presence: true, uniqueness: true

  scope :for_network, ->(network) { where(network: network) }
  scope :starting_from, ->(date) { where("reward_date >= ?", date) if date.present? }
  scope :ending_at, ->(date) { where("reward_date <= ?", date) if date.present? }
  scope :ordered, -> { order(reward_date: :desc) }

  def self.daily_rollup
    includes(:network).ordered.group_by { [ _1.network.slug, _1.reward_date ] }.map do |(slug, date), events|
      {
        network: slug,
        date: date.iso8601,
        amount: events.sum { _1.amount.to_i }.to_s,
        event_count: events.size
      }
    end
  end
end
