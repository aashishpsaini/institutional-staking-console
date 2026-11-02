# frozen_string_literal: true

module Api
  module V1
    class PortfolioController < ApplicationController
      def show
        render json: {
          data: Network.all.map { portfolio_for(_1) },
          last_synced_at: Current.organization.sync_runs.latest_rewards_sync&.finished_at&.iso8601
        }
      end

      private
        def portfolio_for(network)
          validators = Current.organization.validators.for_network(network)

          {
            protocol: network.slug,
            balance: Current.organization.staked_balance_for(network),
            total_rewards_received: Current.organization.total_rewards_for(network),
            updated_at: validators.maximum(:updated_at)&.iso8601,
            started_at: validators.minimum(:created_at)&.iso8601
          }
        end
    end
  end
end
