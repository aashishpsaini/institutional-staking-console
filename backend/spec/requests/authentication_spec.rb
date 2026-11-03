# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API authentication", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }

  it "rejects a missing api key with a 401 error envelope" do
    get "/api/v1/portfolio"

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body["error"]).to include("code" => "unauthorized", "message" => be_present)
  end

  it "rejects an unknown api key" do
    get "/api/v1/portfolio", headers: auth_headers("wrong-key")
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a revoked api key" do
    key.revoke!
    get "/api/v1/portfolio", headers: auth_headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "accepts a valid key and records when it was last used" do
    expect { get "/api/v1/portfolio", headers: auth_headers }.to change { key.reload.last_used_at }.from(nil)
    expect(response).to have_http_status(:ok)
  end

  it "never stores the plaintext token" do
    expect(key.token_digest).to eq(Digest::SHA256.hexdigest("test-key"))
    expect(ApiKey.column_names).not_to include("token")
  end

  it "returns a JSON 404 for unknown routes" do
    get "/api/v1/nope", headers: auth_headers
    expect(response).to have_http_status(:not_found)
    expect(error_code).to eq("not_found")
  end
end
