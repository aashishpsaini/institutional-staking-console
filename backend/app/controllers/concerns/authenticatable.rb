# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  private
    def authenticate
      api_key = ApiKey.authenticate(request.headers["X-Api-Key"])

      if api_key
        Current.api_key = api_key
        Current.organization = api_key.organization
      else
        render_error :unauthorized, status: :unauthorized, message: "Missing or invalid X-Api-Key header"
      end
    end
end
