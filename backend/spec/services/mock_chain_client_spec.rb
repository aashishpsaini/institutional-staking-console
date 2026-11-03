# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChainClients::MockChainClient do
  let(:org) { Organization.create!(name: "Test Org") }
  let(:eth) { network!(:ethereum) }
  let!(:validator) { Validator.create!(organization: org, network: eth, external_ref: "0xv", balance: "32000000000000000000") }
  let(:day) { Date.new(2024, 6, 1) }

  it "implements the ChainClients::Base contract" do
    expect(described_class.new).to be_a(ChainClients::Base)
    expect(ChainClients.current).to be_a(described_class)
  end

  it "returns the same reward for a day regardless of the requested window" do
    narrow = described_class.new.fetch_rewards(org, from: day, to: day)
    wide = described_class.new.fetch_rewards(org, from: day - 10, to: day + 10)

    expect(wide.find { _1[:date] == day }).to eq(narrow.sole)
  end

  it "derives rewards from balance × APR using integer math" do
    reward = described_class.new.fetch_rewards(org, from: day, to: day).sole

    expect(reward[:amount]).to match(/\A\d+\z/)
    expect(reward[:amount].to_i).to be_within(3).percent_of(32 * 10**18 * 320 / 10_000 / 365)
  end
end
