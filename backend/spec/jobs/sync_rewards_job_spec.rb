# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRewardsJob, type: :job do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:eth) { network!(:ethereum) }
  let!(:sol) { network!(:solana) }
  let!(:eth_val) { Validator.create!(organization: org, network: eth, external_ref: "0xtest", balance: "32000000000000000000") }
  let!(:sol_val) { Validator.create!(organization: org, network: sol, external_ref: "SOLtest", balance: "100000000000") }

  let(:today) { Date.current }

  def sync!(from: today - 2, to: today)
    run = org.sync_runs.create!(kind: "rewards", from_date: from, to_date: to)
    described_class.perform_now(run.id)
    run.reload
  end

  it "creates one reward event per validator per day" do
    expect { sync! }.to change(RewardEvent, :count).by(6) # 3 days × 2 validators
  end

  it "is idempotent — re-running the same window does not change rows or totals" do
    sync!
    snapshot = RewardEvent.order(:external_id).pluck(:external_id, :amount)

    expect { sync! }.not_to change(RewardEvent, :count)
    expect(RewardEvent.order(:external_id).pluck(:external_id, :amount)).to eq(snapshot)
  end

  it "is idempotent across overlapping windows" do
    sync!(from: today - 5, to: today - 2)
    sync!(from: today - 3, to: today)

    expect(RewardEvent.count).to eq(12) # 6 distinct days × 2 validators
    expect(RewardEvent.group(:external_id).count.values).to all(eq(1))
  end

  it "overwrites a corrected amount from the chain rather than adding to it" do
    sync!(from: today, to: today)
    event = RewardEvent.find_by!(network: eth)
    event.update_column(:amount, "1")

    sync!(from: today, to: today)
    expect(event.reload.amount).not_to eq("1")
    expect(RewardEvent.count).to eq(2)
  end

  it "does not touch other organizations' rewards" do
    other = Organization.create!(name: "Other")
    RewardEvent.create!(organization: other, network: eth, reward_date: today, amount: "7", external_id: "ethereum:0xtest:#{today.iso8601}")

    sync!(from: today, to: today)
    expect(other.reward_events.sole.amount).to eq("7")
  end

  it "records a completed sync run with the number of rows upserted" do
    run = sync!
    expect(run).to have_attributes(status: "completed", records_upserted: 6, started_at: be_present, finished_at: be_present)
  end

  it "marks the sync run failed and re-raises when the chain client errors" do
    allow_any_instance_of(ChainClients::MockChainClient).to receive(:fetch_rewards).and_raise(StandardError, "chain unavailable")
    run = org.sync_runs.create!(kind: "rewards", from_date: today, to_date: today)

    expect { described_class.perform_now(run.id) }.to raise_error(StandardError, "chain unavailable")
    expect(run.reload).to have_attributes(status: "failed", error_message: "chain unavailable", finished_at: be_present)
  end

  it "rejects malformed amounts from the adapter instead of persisting them" do
    allow_any_instance_of(ChainClients::MockChainClient).to receive(:fetch_rewards)
      .and_return([ { network: "ethereum", date: today, amount: 1.5, external_id: "x" } ])
    run = org.sync_runs.create!(kind: "rewards", from_date: today, to_date: today)

    expect { described_class.perform_now(run.id) }.to raise_error(ChainClients::Error, /Malformed reward amount/)
    expect(RewardEvent.count).to eq(0)
    expect(run.reload.status).to eq("failed")
  end

  it "retries transient chain outages" do
    allow_any_instance_of(ChainClients::MockChainClient).to receive(:fetch_rewards).and_raise(ChainClients::UnavailableError)
    run = org.sync_runs.create!(kind: "rewards", from_date: today, to_date: today)

    expect { described_class.perform_now(run.id) }.to have_enqueued_job(described_class).with(run.id)
  end
end
