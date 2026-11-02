# frozen_string_literal: true

module Api
  module V1
    class PortfolioController < ApplicationController
      def show
        org = current_organization

        validators_by_network = org.validators.includes(:network).group_by(&:network)
        rewards_by_network = org.reward_events.includes(:network).group_by(&:network)

        last_sync = org.sync_runs.where(kind: "rewards", status: "completed")
                       .order(finished_at: :desc).first

        data = Network.all.map do |network|
          validators = validators_by_network[network] || []
          rewards = rewards_by_network[network] || []

          total_balance = validators.sum { |v| v.balance.to_i }
          total_rewards = rewards.sum { |r| r.amount.to_i }

          {
            protocol: network.slug,
            balance: total_balance.to_s,
            total_rewards_received: total_rewards.to_s,
            updated_at: validators.map(&:updated_at).compact.max&.iso8601,
            started_at: validators.map(&:created_at).compact.min&.iso8601
          }
        end

        render json: { data: data, last_synced_at: last_sync&.finished_at&.iso8601 }
      end
    end
  end
end
