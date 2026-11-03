# frozen_string_literal: true

# Partial, case-insensitive matches — e.g. "token" also filters "token_digest".
Rails.application.config.filter_parameters += %i[ passw email secret token _key crypt salt certificate otp ssn ]
