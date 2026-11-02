# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  private
    def authenticate
      Current.api_key = ApiKey.find_by(token: api_key_token) if api_key_token.present?
      Current.organization = Current.api_key&.organization

      render json: { error: "unauthorized" }, status: :unauthorized unless Current.organization
    end

    def api_key_token
      request.headers["X-Api-Key"].presence
    end

    def current_organization
      Current.organization
    end
end
