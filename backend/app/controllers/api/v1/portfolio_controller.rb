# frozen_string_literal: true

module Api
  module V1
    class PortfolioController < ApplicationController
      def show
        # TODO(candidate): aggregate validator balances + reward_events per network
        # Expected shape:
        # {
        #   data: [
        #     { protocol:, balance:, total_rewards_received:, updated_at:, started_at: },
        #     ...
        #   ],
        #   last_synced_at:
        # }
        render json: { data: [], last_synced_at: nil, error: "not_implemented" }, status: :not_implemented
      end
    end
  end
end
