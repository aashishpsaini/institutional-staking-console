# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Stake Operations API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let!(:other_org) { Organization.create!(name: "Other Org") }
  let!(:eth) { Network.find_or_create_by!(slug: "ethereum") { |n| n.display_name = "Ethereum" } }
  let!(:sol) { Network.find_or_create_by!(slug: "solana") { |n| n.display_name = "Solana" } }
  let(:headers) { { "X-Api-Key" => "test-key", "Content-Type" => "application/json" } }

  describe "POST /api/v1/stake_operations" do
    let(:valid_params) { { network: "ethereum", action: "stake", amount: "1000000000" } }

    it "creates a stake operation and returns submitted status" do
      post "/api/v1/stake_operations", params: valid_params.to_json, headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body["data"]
      expect(body["status"]).to eq("submitted")
      expect(body["external_id"]).to start_with("mock-stake-")
      expect(body["amount"]).to eq("1000000000")
      expect(body["network"]).to eq("ethereum")
      expect(body["action"]).to eq("stake")
    end

    it "creates an unstake operation" do
      post "/api/v1/stake_operations",
           params: { network: "solana", action: "unstake", amount: "500" }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]["action"]).to eq("unstake")
    end

    it "rejects unknown network with 422" do
      post "/api/v1/stake_operations",
           params: { network: "cardano", action: "stake", amount: "1000" }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("unknown_network")
    end

    it "rejects invalid action with 422" do
      post "/api/v1/stake_operations",
           params: { network: "ethereum", action: "swap", amount: "1000" }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects zero amount" do
      post "/api/v1/stake_operations",
           params: { network: "ethereum", action: "stake", amount: "0" }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects negative amount" do
      post "/api/v1/stake_operations",
           params: { network: "ethereum", action: "stake", amount: "-100" }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects float amount" do
      post "/api/v1/stake_operations",
           params: { network: "ethereum", action: "stake", amount: "10.5" }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects unauthorized requests" do
      post "/api/v1/stake_operations", params: valid_params.to_json,
           headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/stake_operations" do
    before do
      org.stake_operations.create!(network: eth, action: "stake", amount: "5000", status: "submitted", external_id: "mock-1")
      org.stake_operations.create!(network: sol, action: "unstake", amount: "2000", status: "pending")
    end

    it "lists operations for the authenticated org" do
      get "/api/v1/stake_operations", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(2)
    end

    it "returns operations ordered by created_at desc" do
      get "/api/v1/stake_operations", headers: headers
      data = response.parsed_body["data"]
      timestamps = data.map { |d| d["created_at"] }
      expect(timestamps).to eq(timestamps.sort.reverse)
    end

    it "does not leak operations from other organizations" do
      other_org.stake_operations.create!(network: eth, action: "stake", amount: "999", status: "pending")
      get "/api/v1/stake_operations", headers: headers
      expect(response.parsed_body["data"].size).to eq(2) # only our org's ops
    end

    it "returns amounts as strings" do
      get "/api/v1/stake_operations", headers: headers
      response.parsed_body["data"].each do |op|
        expect(op["amount"]).to be_a(String)
      end
    end
  end
end

