# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :organization, :api_key
end
