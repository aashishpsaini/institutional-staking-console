# frozen_string_literal: true

class SyncRewardsJob < ApplicationJob
  queue_as :default

  def perform(organization_id, from: Date.today - 7, to: Date.today)
    organization = Organization.find(organization_id)
    client = ChainClients::MockChainClient.new

    # TODO(candidate):
    # 1) create SyncRun
    # 2) fetch_rewards from client
    # 3) upsert RewardEvent by external_id (idempotent)
    # 4) mark SyncRun finished
    raise NotImplementedError, "Implement idempotent rewards sync"
  end
end
