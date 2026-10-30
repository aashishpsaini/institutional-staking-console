# frozen_string_literal: true

class Network < ApplicationRecord
  has_many :validators, dependent: :restrict_with_exception
  has_many :reward_events, dependent: :restrict_with_exception
  has_many :stake_operations, dependent: :restrict_with_exception
end
