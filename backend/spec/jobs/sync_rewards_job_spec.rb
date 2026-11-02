# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRewardsJob, type: :job do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:eth) { Network.find_or_create_by!(slug: "ethereum") { |n| n.display_name = "Ethereum" } }
  let!(:sol) { Network.find_or_create_by!(slug: "solana") { |n| n.display_name = "Solana" } }
  let!(:eth_val) { Validator.create!(organization: org, network: eth, external_ref: "0xtest", balance: "1000") }
  let!(:sol_val) { Validator.create!(organization: org, network: sol, external_ref: "SOLtest", balance: "2000") }

  let(:from) { Date.today - 2 }
  let(:to) { Date.today }

  describe "#perform" do
    it "creates reward events from the mock chain client" do
      expect {
        described_class.perform_now(org.id, from: from, to: to)
      }.to change(RewardEvent, :count).by(6) # 3 days × 2 networks
    end

    it "is idempotent — re-running does not create duplicates" do
      described_class.perform_now(org.id, from: from, to: to)
      initial_count = RewardEvent.count

      described_class.perform_now(org.id, from: from, to: to)
      expect(RewardEvent.count).to eq(initial_count)
    end

    it "creates a completed sync_run record on success" do
      described_class.perform_now(org.id, from: from, to: to)

      sync_run = org.sync_runs.last
      expect(sync_run.kind).to eq("rewards")
      expect(sync_run.status).to eq("completed")
      expect(sync_run.finished_at).to be_present
    end

    it "marks sync_run as failed when chain client raises" do
      allow_any_instance_of(ChainClients::MockChainClient)
        .to receive(:fetch_rewards).and_raise(StandardError, "chain unavailable")

      expect {
        described_class.perform_now(org.id, from: from, to: to)
      }.to raise_error(StandardError, "chain unavailable")

      sync_run = org.sync_runs.last
      expect(sync_run.status).to eq("failed")
      expect(sync_run.finished_at).to be_present
    end

    it "stores correct amounts as string integers" do
      described_class.perform_now(org.id, from: from, to: to)
      RewardEvent.all.each do |event|
        expect(event.amount).to match(/\A\d+\z/)
      end
    end
  end
end
