# frozen_string_literal: true

module Api
  module V1
    class RewardsController < ApplicationController
      before_action :set_network, if: -> { params[:network].present? }

      def index
        events = Current.organization.reward_events
          .then { @network ? _1.for_network(@network) : _1 }
          .starting_from(parse_date(params[:start]))
          .ending_at(parse_date(params[:end]))

        render json: { data: events.daily_rollup }
      rescue Date::Error, TypeError
        render json: { error: "invalid_date_format" }, status: :unprocessable_entity
      end

      private
        def set_network
          @network = Network.find_by!(slug: params[:network])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "unknown_network" }, status: :unprocessable_entity
        end

        def parse_date(value)
          value&.to_date
        end
    end
  end
end
