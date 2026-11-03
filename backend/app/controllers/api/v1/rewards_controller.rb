# frozen_string_literal: true

module Api
  module V1
    class RewardsController < ApplicationController
      def index
        network, start_date, end_date = network_param, date_param(:start), date_param(:end)
        if start_date && end_date && start_date > end_date
          raise InvalidParameter.new(:invalid_date_range, "start must be on or before end")
        end

        events = Current.organization.reward_events
          .then { network ? _1.for_network(network) : _1 }
          .starting_from(start_date)
          .ending_at(end_date)

        render json: {
          data: events.daily_rollup,
          meta: { network: network&.slug, start: start_date&.iso8601, end: end_date&.iso8601 }
        }
      end
    end
  end
end
