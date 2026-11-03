# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Portfolio API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let!(:eth) { network!(:ethereum) }
  let!(:sol) { network!(:solana) }
  let!(:eth_validator) { Validator.create!(organization: org, network: eth, external_ref: "0xabc", balance: "32000000000000000000") }
  let!(:sol_validator) { Validator.create!(organization: org, network: sol, external_ref: "Stake111", balance: "100000000000") }

  def row_for(slug)
    response.parsed_body["data"].find { _1["network"] == slug }
  end

  describe "GET /api/v1/portfolio" do
    it "returns per-network balances with zero rewards when none synced" do
      get "/api/v1/portfolio", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(2)
      expect(row_for("ethereum")).to include("balance" => "32000000000000000000", "total_rewards_received" => "0", "validator_count" => 1)
      expect(row_for("solana")).to include("balance" => "100000000000", "total_rewards_received" => "0")
    end

    it "includes network metadata so clients can format amounts" do
      get "/api/v1/portfolio", headers: auth_headers
      expect(row_for("ethereum")["network_details"]).to eq("slug" => "ethereum", "display_name" => "Ethereum", "symbol" => "ETH", "decimals" => 18)
    end

    it "aggregates total_rewards_received from synced reward events" do
      RewardEvent.create!(organization: org, network: eth, reward_date: Date.current, amount: "10000000", external_id: "eth-1")
      RewardEvent.create!(organization: org, network: eth, reward_date: Date.yesterday, amount: "5000000", external_id: "eth-2")

      get "/api/v1/portfolio", headers: auth_headers
      expect(row_for("ethereum")["total_rewards_received"]).to eq("15000000")
      expect(row_for("solana")["total_rewards_received"]).to eq("0")
    end

    it "sums balances across validators beyond 64-bit integer range without precision loss" do
      Validator.create!(organization: org, network: eth, external_ref: "0xdef", balance: "9223372036854775807000")

      get "/api/v1/portfolio", headers: auth_headers
      expect(row_for("ethereum")).to include("balance" => "9255372036854775807000", "validator_count" => 2)
    end

    it "does not include other organizations' positions or rewards" do
      other = Organization.create!(name: "Other")
      Validator.create!(organization: other, network: eth, external_ref: "0xother", balance: "1")
      RewardEvent.create!(organization: other, network: eth, reward_date: Date.current, amount: "999", external_id: "eth-1")

      get "/api/v1/portfolio", headers: auth_headers
      expect(row_for("ethereum")).to include("balance" => "32000000000000000000", "total_rewards_received" => "0")
    end

    it "returns all amounts as strings, never floats" do
      get "/api/v1/portfolio", headers: auth_headers
      response.parsed_body["data"].each do |row|
        expect(row.values_at("balance", "total_rewards_received")).to all(be_a(String))
      end
    end

    it "reports the latest completed rewards sync time" do
      finished = 1.hour.ago.change(usec: 0)
      org.sync_runs.create!(kind: "rewards", status: "completed", from_date: Date.yesterday, to_date: Date.current, finished_at: finished)
      org.sync_runs.create!(kind: "rewards", status: "failed", from_date: Date.yesterday, to_date: Date.current, finished_at: Time.current)

      get "/api/v1/portfolio", headers: auth_headers
      expect(response.parsed_body.dig("meta", "last_synced_at")).to eq(finished.iso8601)
    end

    it "returns last_synced_at as nil when no syncs completed" do
      get "/api/v1/portfolio", headers: auth_headers
      expect(response.parsed_body.dig("meta", "last_synced_at")).to be_nil
    end
  end
end
