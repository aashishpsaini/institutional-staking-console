# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Portfolio API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let!(:eth) { Network.find_or_create_by!(slug: "ethereum") { |n| n.display_name = "Ethereum" } }
  let!(:sol) { Network.find_or_create_by!(slug: "solana") { |n| n.display_name = "Solana" } }
  let!(:eth_validator) do
    Validator.create!(organization: org, network: eth, external_ref: "0xabc", balance: "32000000000000000000")
  end
  let!(:sol_validator) do
    Validator.create!(organization: org, network: sol, external_ref: "Stake111", balance: "100000000000")
  end

  let(:headers) { { "X-Api-Key" => "test-key" } }

  describe "GET /api/v1/portfolio" do
    it "rejects missing api key with 401" do
      get "/api/v1/portfolio"
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("unauthorized")
    end

    it "rejects invalid api key with 401" do
      get "/api/v1/portfolio", headers: { "X-Api-Key" => "wrong-key" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns portfolio with balances and zero rewards when none synced" do
      get "/api/v1/portfolio", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body["data"].size).to eq(2)

      eth_row = body["data"].find { |d| d["protocol"] == "ethereum" }
      expect(eth_row["balance"]).to eq("32000000000000000000")
      expect(eth_row["total_rewards_received"]).to eq("0")

      sol_row = body["data"].find { |d| d["protocol"] == "solana" }
      expect(sol_row["balance"]).to eq("100000000000")
      expect(sol_row["total_rewards_received"]).to eq("0")
    end

    it "aggregates total_rewards_received from synced reward events" do
      RewardEvent.create!(organization: org, network: eth, reward_date: Date.today,
                          amount: "10000000", external_id: "eth-1")
      RewardEvent.create!(organization: org, network: eth, reward_date: Date.yesterday,
                          amount: "5000000", external_id: "eth-2")

      get "/api/v1/portfolio", headers: headers
      eth_row = response.parsed_body["data"].find { |d| d["protocol"] == "ethereum" }
      expect(eth_row["total_rewards_received"]).to eq("15000000")
    end

    it "returns all amounts as strings, never floats" do
      get "/api/v1/portfolio", headers: headers
      response.parsed_body["data"].each do |row|
        expect(row["balance"]).to be_a(String)
        expect(row["total_rewards_received"]).to be_a(String)
      end
    end

    it "includes last_synced_at from completed sync runs" do
      finished = 1.hour.ago
      org.sync_runs.create!(kind: "rewards", status: "completed", finished_at: finished)

      get "/api/v1/portfolio", headers: headers
      expect(response.parsed_body["last_synced_at"]).to be_present
    end

    it "returns last_synced_at as nil when no syncs completed" do
      get "/api/v1/portfolio", headers: headers
      expect(response.parsed_body["last_synced_at"]).to be_nil
    end
  end
end
