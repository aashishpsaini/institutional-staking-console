# frozen_string_literal: true

class RewardEvent < ApplicationRecord
  belongs_to :organization
  belongs_to :network

  validates :reward_date, presence: true
  validates :amount, presence: true
  validates :external_id, presence: true, uniqueness: true

  scope :for_network, ->(slug) { joins(:network).where(networks: { slug: slug }) }
  scope :between_dates, ->(from, to) { where(reward_date: from..to) }
end
