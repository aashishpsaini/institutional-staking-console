# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Records deleted between enqueue and perform — nothing left to do.
  discard_on ActiveJob::DeserializationError
end
