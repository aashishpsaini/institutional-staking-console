# frozen_string_literal: true

module Api
  module V1
    class StakeOperationsController < ApplicationController
      def index
        ops = current_organization.stake_operations.order(created_at: :desc).limit(100)
        render json: {
          data: ops.map { |op| serialize(op) }
        }
      end

      def create
        network = Network.find_by(slug: params.require(:network))
        return render json: { error: "unknown_network" }, status: :unprocessable_entity unless network

        op = current_organization.stake_operations.new(
          network: network,
          action: params.require(:action),
          amount: params.require(:amount).to_s,
          status: "pending"
        )

        unless op.valid?
          return render json: { error: "validation_failed", details: op.errors.full_messages }, status: :unprocessable_entity
        end

        # TODO(candidate): persist, call ChainClients::MockChainClient#submit_stake,
        # set external_id + status=submitted (or enqueue confirmation job)
        render json: { error: "not_implemented", hint: "Wire ChainClient submit + persist operation" }, status: :not_implemented
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
