# frozen_string_literal: true

module Api
  module V1
    class SyncController < ApplicationController
      DEFAULT_WINDOW = 7.days

      # Returns the in-progress run instead of enqueuing a duplicate, so repeated
      # clicks don't pile up jobs for the same tenant.
      def rewards
        sync_run = Current.organization.sync_runs.in_progress.find_by(kind: "rewards") || enqueue_rewards_sync
        render json: { data: SyncRunSerializer.call(sync_run) }, status: :accepted
      end

      def show
        render json: { data: SyncRunSerializer.call(Current.organization.sync_runs.find(params[:id])) }
      end

      private
        def enqueue_rewards_sync
          to = date_param(:to) || Date.current
          from = date_param(:from) || (to - DEFAULT_WINDOW)

          Current.organization.sync_runs.create!(kind: "rewards", status: "queued", from_date: from, to_date: to).tap do
            SyncRewardsJob.perform_later(_1.id)
          end
        end
    end
  end
end
