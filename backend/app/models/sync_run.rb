# frozen_string_literal: true

class SyncRun < ApplicationRecord
  STATUSES = %w[ queued running completed failed ].freeze
  IN_PROGRESS_STATUSES = %w[ queued running ].freeze
  KINDS = %w[ rewards ].freeze
  MAX_WINDOW_DAYS = 90
  STALE_AFTER = 15.minutes

  belongs_to :organization

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :from_date, :to_date, presence: true
  validate :window_is_sane

  scope :in_progress, -> { where(status: IN_PROGRESS_STATUSES).where(created_at: STALE_AFTER.ago..) }

  def self.latest_completed(kind)
    where(kind: kind.to_s, status: "completed").order(finished_at: :desc).first
  end

  def start!
    update!(status: "running", started_at: Time.current, error_message: nil)
  end

  def complete!(records_upserted:)
    update!(status: "completed", records_upserted: records_upserted, finished_at: Time.current)
  end

  def fail!(error)
    update!(status: "failed", error_message: error.message.truncate(500), finished_at: Time.current)
  end

  private
    def window_is_sane
      return unless from_date && to_date

      if from_date > to_date
        errors.add(:from_date, "must be on or before to_date")
      elsif (to_date - from_date).to_i >= MAX_WINDOW_DAYS
        errors.add(:base, "Sync window cannot exceed #{MAX_WINDOW_DAYS} days")
      end

      errors.add(:to_date, "cannot be in the future") if to_date > Date.current
    end
end
