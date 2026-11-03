# frozen_string_literal: true

module SyncRunSerializer
  module_function

  def call(sync_run)
    {
      id: sync_run.id,
      kind: sync_run.kind,
      status: sync_run.status,
      from: sync_run.from_date.iso8601,
      to: sync_run.to_date.iso8601,
      records_upserted: sync_run.records_upserted,
      error_message: sync_run.error_message,
      created_at: sync_run.created_at.iso8601,
      started_at: sync_run.started_at&.iso8601,
      finished_at: sync_run.finished_at&.iso8601
    }
  end
end
