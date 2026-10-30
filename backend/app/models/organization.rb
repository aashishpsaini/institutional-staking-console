# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :api_keys, dependent: :destroy
  has_many :validators, dependent: :destroy
  has_many :reward_events, dependent: :destroy
  has_many :stake_operations, dependent: :destroy
  has_many :sync_runs, dependent: :destroy
end
