# frozen_string_literal: true

class Validator < ApplicationRecord
  belongs_to :organization
  belongs_to :network
end
