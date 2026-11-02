# frozen_string_literal: true

module Api
  module V1
    class StakeOperationsController < ApplicationController
      before_action :set_network, only: :create
      before_action :ensure_valid_operation, only: :create

      def index
        operations = Current.organization.stake_operations.includes(:network).order(created_at: :desc).limit(100)
        render json: { data: operations.map(&:serialize) }
      end

      def create
        operation = Current.organization.stake_operations.create!(
          network: @network,
          action: operation_action,
          amount: operation_amount
        )

        operation.submit_to_chain!
        render json: { data: operation.serialize }, status: :created
      end

      private
        def set_network
          @network = Network.find_by(slug: params[:network])
          render json: { error: "unknown_network" }, status: :unprocessable_entity unless @network
        end

        def ensure_valid_operation
          if operation_amount.blank? || !operation_amount.match?(/\A[1-9]\d*\z/)
            render json: { error: "validation_failed", details: [ "Amount must be a positive integer string" ] }, status: :unprocessable_entity
          elsif !StakeOperation::ACTIONS.include?(operation_action)
            render json: { error: "validation_failed", details: [ "Action must be one of: #{StakeOperation::ACTIONS.join(', ')}" ] }, status: :unprocessable_entity
          end
        end

        def operation_action
          request.request_parameters["action"] || params[:action_name]
        end

        def operation_amount
          params[:amount].to_s
        end
    end
  end
end
