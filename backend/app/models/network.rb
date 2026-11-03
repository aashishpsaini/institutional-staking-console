# frozen_string_literal: true

class Network < ApplicationRecord
  has_many :validators, dependent: :restrict_with_exception
  has_many :reward_events, dependent: :restrict_with_exception
  has_many :stake_operations, dependent: :restrict_with_exception

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_-]+\z/ }
  validates :display_name, :symbol, presence: true
  validates :decimals, numericality: { only_integer: true, in: 0..36 }

  scope :ordered, -> { order(:slug) }
end
