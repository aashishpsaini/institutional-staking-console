# frozen_string_literal: true

module Api
  module V1
    class NetworksController < ApplicationController
      def index
        render json: { data: Network.ordered.map { NetworkSerializer.call(_1) } }
      end
    end
  end
end
