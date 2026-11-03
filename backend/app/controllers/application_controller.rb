# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ErrorHandling
  include Authenticatable

  around_action :tag_logs_with_organization

  private
    # Tags every log line for the request with the tenant; the API key itself is never logged.
    def tag_logs_with_organization(&)
      logger.tagged("org=#{Current.organization&.id}", &)
    end
end
