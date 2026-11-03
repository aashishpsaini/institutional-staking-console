# frozen_string_literal: true

module SpecHelpers
  NETWORKS = {
    ethereum: { display_name: "Ethereum", symbol: "ETH", decimals: 18 },
    solana: { display_name: "Solana", symbol: "SOL", decimals: 9 }
  }.freeze

  def network!(slug)
    Network.find_or_create_by!(slug: slug.to_s) { _1.assign_attributes(NETWORKS.fetch(slug.to_sym)) }
  end

  def auth_headers(token = "test-key")
    { "X-Api-Key" => token, "Content-Type" => "application/json" }
  end

  def error_code
    response.parsed_body.dig("error", "code")
  end
end
