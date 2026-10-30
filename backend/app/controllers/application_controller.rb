# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Authenticatable

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { error: "validation_failed", details: e.record.errors.full_messages }, status: :unprocessable_entity
  end
end
