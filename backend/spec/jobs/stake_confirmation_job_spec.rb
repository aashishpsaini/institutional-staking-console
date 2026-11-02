# frozen_string_literal: true

require "rails_helper"

RSpec.describe StakeConfirmationJob, type: :job do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:eth) { Network.find_or_create_by!(slug: "ethereum") { |n| n.display_name = "Ethereum" } }
  let!(:op) do
    org.stake_operations.create!(
      network: eth,
      action: "stake",
      amount: "1000",
      status: "submitted",
      external_id: "mock-123"
    )
  end

  it "transitions submitted operation to confirmed" do
    described_class.perform_now(op.id)
    expect(op.reload.status).to eq("confirmed")
  end

  it "does not alter already confirmed or failed operations" do
    op.update!(status: "failed")
    described_class.perform_now(op.id)
    expect(op.reload.status).to eq("failed")
  end
end
