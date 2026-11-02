# frozen_string_literal: true

class Validator < ApplicationRecord
  belongs_to :organization
  belongs_to :network

  validates :external_ref, presence: true, uniqueness: { scope: %i[organization_id network_id] }
  validates :balance, presence: true
end
