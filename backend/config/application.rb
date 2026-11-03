# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module StakingConsole
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    # In-process adapter keeps the MVP dependency-free; jobs are plain ActiveJob,
    # so switching to Sidekiq/Solid Queue is a one-line change here.
    config.active_job.queue_adapter = :async
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "dev-only-secret-key-base-change-me")

    # Adapter behind the ChainClients boundary (see app/services/chain_clients.rb).
    config.x.chain_client = ENV.fetch("CHAIN_CLIENT", "ChainClients::MockChainClient")

    config.log_tags = [ :request_id ]
  end
end
