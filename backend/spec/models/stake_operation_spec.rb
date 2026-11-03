# frozen_string_literal: true

require "rails_helper"

RSpec.describe StakeOperation do
  let(:org) { Organization.create!(name: "Test Org") }
  let(:eth) { network!(:ethereum) }
  let(:operation) { org.stake_operations.create!(network: eth, action: "stake", amount: "10") }

  it "starts pending" do
    expect(operation.status).to eq("pending")
  end

  it "allows forward transitions along the lifecycle" do
    operation.update!(status: "submitted")
    operation.update!(status: "confirmed")
    expect(operation).to be_confirmed
  end

  it "rejects transitions out of a terminal state" do
    operation.update!(status: "failed")
    expect { operation.update!(status: "confirmed") }.to raise_error(ActiveRecord::RecordInvalid, /cannot transition from failed to confirmed/)
  end

  it "rejects skipping straight from pending to confirmed" do
    expect(operation.update(status: "confirmed")).to be(false)
  end
end
