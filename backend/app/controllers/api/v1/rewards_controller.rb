# frozen_string_literal: true

module Api
  module V1
    class RewardsController < ApplicationController
      def index
        # TODO(candidate): daily rollup with filters network/start/end
        render json: { data: [], error: "not_implemented" }, status: :not_implemented
      end
    end
  end
end
