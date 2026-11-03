# frozen_string_literal: true

# Service boundary between the app and blockchain SDKs / indexers.
#
# Controllers, models and jobs only ever talk to `ChainClients.current`, which
# returns an adapter implementing `ChainClients::Base`. Swapping the mock for a
# real integration is a config change (`config.x.chain_client`), not a code change.
module ChainClients
  class Error < StandardError; end
  class UnavailableError < Error; end

  def self.current
    Rails.configuration.x.chain_client.constantize.new
  end
end
