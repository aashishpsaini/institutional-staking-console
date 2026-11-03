# frozen_string_literal: true

class Validator < ApplicationRecord
  belongs_to :organization
  belongs_to :network

  validates :external_ref, presence: true, uniqueness: { scope: %i[ organization_id network_id ] }
  validates :balance, format: { with: AmountMath::INTEGER_STRING, message: "must be a non-negative integer string" }

  scope :for_network, ->(network) { where(network: network) }
end
