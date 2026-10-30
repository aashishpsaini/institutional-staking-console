# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  private

  def authenticate!
    token = request.headers["X-Api-Key"].presence
    @current_api_key = ApiKey.find_by(token: token) if token
    return if @current_api_key

    render json: { error: "unauthorized" }, status: :unauthorized
  end

  def current_organization
    @current_api_key.organization
  end
end
