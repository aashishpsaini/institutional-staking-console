# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Networks API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }

  it "lists supported networks with their token metadata" do
    network!(:solana)
    network!(:ethereum)

    get "/api/v1/networks", headers: auth_headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["data"]).to eq([
      { "slug" => "ethereum", "display_name" => "Ethereum", "symbol" => "ETH", "decimals" => 18 },
      { "slug" => "solana", "display_name" => "Solana", "symbol" => "SOL", "decimals" => 9 }
    ])
  end
end
