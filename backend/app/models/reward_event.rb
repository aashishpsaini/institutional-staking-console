# frozen_string_literal: true

class RewardEvent < ApplicationRecord
  belongs_to :organization
  belongs_to :network
end
