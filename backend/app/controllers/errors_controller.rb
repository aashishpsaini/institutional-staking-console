# frozen_string_literal: true

class ErrorsController < ActionController::API
  include ErrorHandling

  def not_found
    render_error :not_found, status: :not_found, message: "No route matches #{request.method} #{request.path}"
  end
end
