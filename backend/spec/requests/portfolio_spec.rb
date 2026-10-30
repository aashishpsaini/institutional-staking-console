# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Portfolio API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }

  it "rejects missing api key" do
    get "/api/v1/portfolio"
    expect(response).to have_http_status(:unauthorized)
  end

  it "TODO: returns aggregated portfolio for seeded validators/rewards" do
    skip "Implement portfolio aggregation"
  end
end
