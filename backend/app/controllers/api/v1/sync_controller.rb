# frozen_string_literal: true

module Api
  module V1
    class SyncController < ApplicationController
      def rewards
        from = params[:from].present? ? params[:from].to_date : 7.days.ago.to_date
        to = params[:to].present? ? params[:to].to_date : Date.today

        SyncRewardsJob.perform_later(current_organization.id, from: from, to: to)

        render json: {
          message: "rewards_sync_enqueued",
          from: from.iso8601,
          to: to.iso8601
        }, status: :accepted
      rescue Date::Error, TypeError
        render json: { error: "invalid_date_format" }, status: :unprocessable_entity
      end
    end
  end
end
