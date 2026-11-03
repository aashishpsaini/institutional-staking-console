# frozen_string_literal: true

require "rails_helper"

RSpec.describe StakeConfirmationJob, type: :job do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:eth) { network!(:ethereum) }
  let!(:op) do
    org.stake_operations.create!(network: eth, action: "stake", amount: "1000", status: "submitted", external_id: "mock-123")
  end

  it "confirms a submitted operation when the chain reports it confirmed" do
    described_class.perform_now(op.id)
    expect(op.reload.status).to eq("confirmed")
  end

  it "marks the operation failed when the chain reports failure" do
    allow_any_instance_of(ChainClients::MockChainClient).to receive(:fetch_operation_status).and_return("failed")
    described_class.perform_now(op.id)
    expect(op.reload.status).to eq("failed")
  end

  it "re-polls while the chain still reports the operation in flight" do
    allow_any_instance_of(ChainClients::MockChainClient).to receive(:fetch_operation_status).and_return("submitted")

    expect { described_class.perform_now(op.id) }.to have_enqueued_job(described_class).with(op.id, 2)
    expect(op.reload.status).to eq("submitted")
  end

  it "gives up and fails the operation after the maximum attempts" do
    allow_any_instance_of(ChainClients::MockChainClient).to receive(:fetch_operation_status).and_return("submitted")

    described_class.perform_now(op.id, described_class::MAX_ATTEMPTS)
    expect(op.reload).to have_attributes(status: "failed", error_message: /Not confirmed/)
  end

  it "leaves terminal operations untouched" do
    op.update!(status: "failed")
    expect(ChainClients::MockChainClient).not_to receive(:new)

    described_class.perform_now(op.id)
    expect(op.reload.status).to eq("failed")
  end

  it "is a no-op for deleted operations" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
