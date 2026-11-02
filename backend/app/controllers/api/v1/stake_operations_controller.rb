# frozen_string_literal: true

module Api
  module V1
    class StakeOperationsController < ApplicationController
      def index
        ops = current_organization.stake_operations
                .includes(:network)
                .order(created_at: :desc)
                .limit(100)

        render json: { data: ops.map { |op| serialize(op) } }
      end

      def create
        network = Network.find_by(slug: params[:network])
        return render json: { error: "unknown_network" }, status: :unprocessable_entity unless network

        amount_str = params[:amount].to_s
        unless amount_str.match?(/\A[1-9]\d*\z/)
          return render json: {
            error: "validation_failed",
            details: ["Amount must be a positive integer string"]
          }, status: :unprocessable_entity
        end

        action_value = request.request_parameters["action"] || request.request_parameters[:action] || params[:action_name]
        unless StakeOperation::ACTIONS.include?(action_value)
          return render json: {
            error: "validation_failed",
            details: ["Action must be one of: #{StakeOperation::ACTIONS.join(', ')}"]
          }, status: :unprocessable_entity
        end

        op = current_organization.stake_operations.create!(
          network: network,
          action: action_value,
          amount: amount_str,
          status: "pending"
        )

        # Submit through the service boundary — never call chain details inline
        client = ChainClients::MockChainClient.new
        result = client.submit_stake(op)
        op.update!(external_id: result[:external_id], status: result[:status])

        render json: { data: serialize(op) }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: "validation_failed", details: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def serialize(op)
        {
          id: op.id,
          network: op.network.slug,
          action: op.action,
          amount: op.amount,
          status: op.status,
          external_id: op.external_id,
          error_message: op.error_message,
          created_at: op.created_at.iso8601
        }
      end
    end
  end
end
