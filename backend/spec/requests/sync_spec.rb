# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sync API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }

  def sync(params = {})
    post "/api/v1/sync/rewards", params: params.to_json, headers: auth_headers
  end

  describe "POST /api/v1/sync/rewards" do
    it "creates a queued sync run, enqueues the job and returns 202" do
      expect { sync }.to have_enqueued_job(SyncRewardsJob).and change(SyncRun, :count).by(1)

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body["data"]).to include(
        "status" => "queued", "kind" => "rewards", "from" => (Date.current - 7).iso8601, "to" => Date.current.iso8601
      )
    end

    it "accepts optional from/to dates" do
      sync(from: (Date.current - 30).iso8601, to: Date.current.iso8601)

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body.dig("data", "from")).to eq((Date.current - 30).iso8601)
    end

    it "returns the in-progress run instead of enqueuing a duplicate" do
      sync
      first_id = response.parsed_body.dig("data", "id")

      expect { sync }.not_to have_enqueued_job(SyncRewardsJob)
      expect(response.parsed_body.dig("data", "id")).to eq(first_id)
    end

    it "returns 422 for an invalid date" do
      sync(from: "invalid-date")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(error_code).to eq("invalid_date_format")
    end

    it "returns 422 for an inverted, oversized or future window" do
      [
        { from: Date.current.iso8601, to: (Date.current - 1).iso8601 },
        { from: (Date.current - 365).iso8601, to: Date.current.iso8601 },
        { from: Date.current.iso8601, to: (Date.current + 1).iso8601 }
      ].each do |params|
        sync(params)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(error_code).to eq("validation_failed")
      end
      expect(SyncRun.count).to eq(0)
    end

    it "rejects unauthorized requests" do
      post "/api/v1/sync/rewards"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/sync/runs/:id" do
    it "returns the run's progress" do
      run = org.sync_runs.create!(kind: "rewards", from_date: Date.yesterday, to_date: Date.current)
      get "/api/v1/sync/runs/#{run.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "status")).to eq("queued")
    end

    it "returns 404 for another organization's run" do
      other = Organization.create!(name: "Other").sync_runs.create!(kind: "rewards", from_date: Date.yesterday, to_date: Date.current)
      get "/api/v1/sync/runs/#{other.id}", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
