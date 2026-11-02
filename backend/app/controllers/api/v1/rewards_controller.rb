# frozen_string_literal: true

module Api
  module V1
    class RewardsController < ApplicationController
      def index
        scope = current_organization.reward_events.includes(:network)

        if params[:network].present?
          network = Network.find_by(slug: params[:network])
          return render json: { error: "unknown_network" }, status: :unprocessable_entity unless network

          scope = scope.where(network: network)
        end

        scope = scope.where("reward_date >= ?", params[:start].to_date) if params[:start].present?
        scope = scope.where("reward_date <= ?", params[:end].to_date) if params[:end].present?

        grouped = scope.order(reward_date: :desc).group_by { |e| [e.network.slug, e.reward_date] }

        data = grouped.map do |(network_slug, reward_date), events|
          daily_total = events.sum { |e| e.amount.to_i }
          {
            network: network_slug,
            date: reward_date.iso8601,
            amount: daily_total.to_s,
            event_count: events.size
          }
        end

        render json: { data: data }
      rescue Date::Error, TypeError
        render json: { error: "invalid_date_format" }, status: :unprocessable_entity
      end
    end
  end
end
