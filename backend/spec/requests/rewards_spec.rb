# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rewards API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let!(:eth) { Network.find_or_create_by!(slug: "ethereum") { |n| n.display_name = "Ethereum" } }
  let!(:sol) { Network.find_or_create_by!(slug: "solana") { |n| n.display_name = "Solana" } }
  let(:headers) { { "X-Api-Key" => "test-key" } }

  before do
    (0..2).each do |i|
      date = Date.today - i
      RewardEvent.create!(organization: org, network: eth, reward_date: date,
                          amount: (10_000 + i * 100).to_s, external_id: "eth-#{i}")
      RewardEvent.create!(organization: org, network: sol, reward_date: date,
                          amount: (5_000 + i * 50).to_s, external_id: "sol-#{i}")
    end
  end

  describe "GET /api/v1/rewards" do
    it "returns daily rollups for all networks" do
      get "/api/v1/rewards", headers: headers
      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.size).to eq(6)
    end

    it "filters by network" do
      get "/api/v1/rewards", params: { network: "ethereum" }, headers: headers
      data = response.parsed_body["data"]
      expect(data).to all(include("network" => "ethereum"))
      expect(data.size).to eq(3)
    end

    it "returns 422 for unknown network" do
      get "/api/v1/rewards", params: { network: "cardano" }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("unknown_network")
    end

    it "filters by date range" do
      get "/api/v1/rewards", params: {
        start: (Date.today - 1).iso8601,
        end: Date.today.iso8601
      }, headers: headers

      data = response.parsed_body["data"]
      dates = data.map { |r| Date.parse(r["date"]) }
      expect(dates).to all(be >= (Date.today - 1))
      expect(dates).to all(be <= Date.today)
    end

    it "returns 422 for invalid date format" do
      get "/api/v1/rewards", params: { start: "not-a-date" }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("invalid_date_format")
    end

    it "combines network and date filters" do
      get "/api/v1/rewards", params: {
        network: "solana",
        start: Date.today.iso8601,
        end: Date.today.iso8601
      }, headers: headers

      data = response.parsed_body["data"]
      expect(data.size).to eq(1)
      expect(data.first["network"]).to eq("solana")
    end

    it "returns amounts as strings" do
      get "/api/v1/rewards", headers: headers
      response.parsed_body["data"].each do |row|
        expect(row["amount"]).to be_a(String)
        expect(row["amount"]).to match(/\A\d+\z/)
      end
    end

    it "returns empty data when no rewards match" do
      get "/api/v1/rewards", params: {
        start: (Date.today + 100).iso8601
      }, headers: headers
      expect(response.parsed_body["data"]).to be_empty
    end

    it "rejects unauthorized requests" do
      get "/api/v1/rewards"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
