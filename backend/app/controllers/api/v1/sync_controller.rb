# frozen_string_literal: true

module Api
  module V1
    class SyncController < ApplicationController
      def rewards
        # TODO(candidate): enqueue SyncRewardsJob for current_organization
        render json: { error: "not_implemented", hint: "Enqueue SyncRewardsJob" }, status: :not_implemented
      end
    end
  end
end
