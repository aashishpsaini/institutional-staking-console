# frozen_string_literal: true

# Only a SHA-256 digest of the token is persisted, so a database leak does not
# leak usable credentials. Tokens are high-entropy random strings, so a fast
# digest (rather than bcrypt) is sufficient and keeps lookups indexable.
class ApiKey < ApplicationRecord
  LAST_USED_RESOLUTION = 1.minute

  belongs_to :organization

  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(revoked_at: nil) }

  class << self
    def digest(token)
      Digest::SHA256.hexdigest(token)
    end

    def authenticate(token)
      return if token.blank?

      active.includes(:organization).find_by(token_digest: digest(token))&.tap(&:record_usage)
    end

    # Returns [api_key, raw_token]; the raw token is only ever available here.
    def issue!(organization:, token: SecureRandom.base58(32))
      [ create!(organization: organization, token: token), token ]
    end
  end

  # Write-only: the plaintext token is never readable back from the model.
  def token=(raw_token)
    self.token_digest = raw_token.presence && self.class.digest(raw_token)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  # Throttled so authenticated reads don't each turn into a write.
  def record_usage
    return if last_used_at&.after?(LAST_USED_RESOLUTION.ago)

    update_column(:last_used_at, Time.current)
  end
end
