# frozen_string_literal: true

module Api
  module V1
    class StakeOperationsController < ApplicationController
      LIST_LIMIT = 100

      def index
        operations = Current.organization.stake_operations.includes(:network).recent.limit(LIST_LIMIT)
        render json: { data: operations.map { StakeOperationSerializer.call(_1) } }
      end

      def show
        operation = Current.organization.stake_operations.find(params[:id])
        render json: { data: StakeOperationSerializer.call(operation) }
      end

      def create
        result = StakeOperations::Request.call(
          organization: Current.organization,
          network: network_param || raise(InvalidParameter.new(:unknown_network, "network is required")),
          action: operation_action,
          amount: params[:amount].to_s.strip,
          idempotency_key: request.headers["Idempotency-Key"]
        )

        render json: { data: StakeOperationSerializer.call(result.operation) }, status: result.created ? :created : :ok
      rescue StakeOperations::Request::IdempotencyConflict
        render_error :idempotency_conflict, status: :conflict,
                     message: "Idempotency-Key was already used with a different request body"
      end

      private
        # `params[:action]` is reserved by Rails for the controller action name,
        # so the JSON body's "action" field is read from the raw request parameters.
        def operation_action
          request.request_parameters["action"].to_s
        end
    end
  end
end
