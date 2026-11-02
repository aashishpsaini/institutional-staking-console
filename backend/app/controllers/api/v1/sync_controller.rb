# frozen_string_literal: true

module Api
  module V1
    class SyncController < ApplicationController
      def rewards
        from = parse_date(params[:from]) || 7.days.ago.to_date
        to = parse_date(params[:to]) || Date.today

        SyncRewardsJob.perform_later Current.organization.id, from: from, to: to

        render json: { message: "rewards_sync_enqueued", from: from.iso8601, to: to.iso8601 }, status: :accepted
      rescue Date::Error, TypeError
        render json: { error: "invalid_date_format" }, status: :unprocessable_entity
      end

      private
        def parse_date(value)
          value&.to_date
        end
    end
  end
end
