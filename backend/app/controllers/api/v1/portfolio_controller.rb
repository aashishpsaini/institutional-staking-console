# frozen_string_literal: true

module Api
  module V1
    class PortfolioController < ApplicationController
      def show
        render json: PortfolioSerializer.call(Portfolio.new(Current.organization))
      end
    end
  end
end
