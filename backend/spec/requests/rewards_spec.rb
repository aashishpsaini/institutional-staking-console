# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rewards API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let!(:eth) { network!(:ethereum) }
  let!(:sol) { network!(:solana) }
  let(:today) { Date.current }

  before do
    (0..2).each do |i|
      date = today - i
      RewardEvent.create!(organization: org, network: eth, reward_date: date, amount: (10_000 + i * 100).to_s, external_id: "eth-#{i}")
      RewardEvent.create!(organization: org, network: sol, reward_date: date, amount: (5_000 + i * 50).to_s, external_id: "sol-#{i}")
    end
  end

  def data = response.parsed_body["data"]

  describe "GET /api/v1/rewards" do
    it "returns one rollup row per network per day, newest first" do
      get "/api/v1/rewards", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(data.size).to eq(6)
      expect(data.map { _1["date"] }).to eq(data.map { _1["date"] }.sort.reverse)
      expect(data.first(2).map { _1["network"] }).to eq(%w[ ethereum solana ])
    end

    it "sums multiple events for the same network and day" do
      RewardEvent.create!(organization: org, network: eth, reward_date: today, amount: "99999999999999999999", external_id: "eth-extra")

      get "/api/v1/rewards", params: { network: "ethereum", start: today.iso8601 }, headers: auth_headers
      expect(data).to eq([ { "network" => "ethereum", "date" => today.iso8601, "amount" => "100000000000000009999", "event_count" => 2 } ])
    end

    it "filters by network" do
      get "/api/v1/rewards", params: { network: "ethereum" }, headers: auth_headers
      expect(data.size).to eq(3)
      expect(data).to all(include("network" => "ethereum"))
    end

    it "filters by inclusive date range" do
      get "/api/v1/rewards", params: { start: (today - 1).iso8601, end: today.iso8601 }, headers: auth_headers
      expect(data.map { _1["date"] }.uniq).to contain_exactly(today.iso8601, (today - 1).iso8601)
    end

    it "combines network and date filters and echoes them in meta" do
      get "/api/v1/rewards", params: { network: "solana", start: today.iso8601, end: today.iso8601 }, headers: auth_headers

      expect(data).to eq([ { "network" => "solana", "date" => today.iso8601, "amount" => "5000", "event_count" => 1 } ])
      expect(response.parsed_body["meta"]).to eq("network" => "solana", "start" => today.iso8601, "end" => today.iso8601)
    end

    it "returns empty data when no rewards match" do
      get "/api/v1/rewards", params: { start: (today + 100).iso8601 }, headers: auth_headers
      expect(data).to be_empty
    end

    it "excludes other organizations' rewards" do
      other = Organization.create!(name: "Other")
      RewardEvent.create!(organization: other, network: eth, reward_date: today, amount: "1", external_id: "eth-0")

      get "/api/v1/rewards", params: { network: "ethereum", start: today.iso8601 }, headers: auth_headers
      expect(data.sole["amount"]).to eq("10000")
    end

    it "returns 422 for an unknown network" do
      get "/api/v1/rewards", params: { network: "cardano" }, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(error_code).to eq("unknown_network")
    end

    it "returns 422 for a non ISO-8601 date" do
      %w[ not-a-date 2024-13-45 5 ].each do |bad|
        get "/api/v1/rewards", params: { start: bad }, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(error_code).to eq("invalid_date_format")
      end
    end

    it "returns 422 when start is after end" do
      get "/api/v1/rewards", params: { start: today.iso8601, end: (today - 1).iso8601 }, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(error_code).to eq("invalid_date_range")
    end

    it "returns amounts as integer strings" do
      get "/api/v1/rewards", headers: auth_headers
      expect(data.map { _1["amount"] }).to all(match(/\A\d+\z/))
    end
  end
end
