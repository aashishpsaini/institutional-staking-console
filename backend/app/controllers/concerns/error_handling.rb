# frozen_string_literal: true

# Every error leaves the API in one envelope:
#   { "error": { "code": "validation_failed", "message": "...", "details": [...] } }
# `code` is stable and machine-readable; `message`/`details` are for humans.
module ErrorHandling
  extend ActiveSupport::Concern

  class InvalidParameter < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super(message)
    end
  end

  included do
    rescue_from ActiveRecord::RecordInvalid do |e|
      render_error :validation_failed, status: :unprocessable_entity,
                   message: "Validation failed", details: e.record.errors.full_messages
    end

    rescue_from ActiveRecord::RecordNotFound do
      render_error :not_found, status: :not_found, message: "Resource not found"
    end

    rescue_from ActionController::ParameterMissing, ActionDispatch::Http::Parameters::ParseError do |e|
      render_error :bad_request, status: :bad_request, message: e.message
    end

    rescue_from InvalidParameter do |e|
      render_error e.code, status: :unprocessable_entity, message: e.message
    end
  end

  private
    def render_error(code, status:, message:, details: [])
      render json: { error: { code: code.to_s, message: message, details: details } }, status: status
    end

    def date_param(name)
      value = params[name].presence
      value && Date.iso8601(value.to_s)
    rescue Date::Error
      raise InvalidParameter.new(:invalid_date_format, "#{name} must be an ISO-8601 date (YYYY-MM-DD)")
    end

    def network_param(name = :network)
      slug = params[name].presence
      return unless slug

      Network.find_by(slug: slug.to_s) || raise(InvalidParameter.new(:unknown_network, "Unknown network: #{slug}"))
    end
end
