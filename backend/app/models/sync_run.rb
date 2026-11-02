# frozen_string_literal: true

class SyncRun < ApplicationRecord
  STATUSES = %w[running completed failed].freeze
  KINDS = %w[rewards].freeze

  belongs_to :organization

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  scope :completed, -> { where(status: "completed") }
  scope :latest_for, ->(kind) { where(kind: kind).order(finished_at: :desc).first }
end
