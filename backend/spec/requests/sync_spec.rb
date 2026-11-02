# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sync API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let(:headers) { { "X-Api-Key" => "test-key" } }

  describe "POST /api/v1/sync/rewards" do
    it "enqueues a rewards sync job and returns 202" do
      expect {
        post "/api/v1/sync/rewards", headers: headers
      }.to have_enqueued_job(SyncRewardsJob)

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body["message"]).to eq("rewards_sync_enqueued")
    end

    it "accepts optional from/to date params" do
      post "/api/v1/sync/rewards", params: {
        from: (Date.today - 30).iso8601,
        to: Date.today.iso8601
      }, headers: headers

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body["from"]).to eq((Date.today - 30).iso8601)
    end

    it "returns 422 for invalid date" do
      post "/api/v1/sync/rewards", params: { from: "invalid-date" }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("invalid_date_format")
    end

    it "rejects unauthorized requests" do
      post "/api/v1/sync/rewards"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

