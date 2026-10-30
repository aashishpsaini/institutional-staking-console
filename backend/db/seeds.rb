# frozen_string_literal: true

org = Organization.find_or_create_by!(name: "Demo Institution")
ApiKey.find_or_create_by!(organization: org, token: "demo-key")

eth = Network.find_or_create_by!(slug: "ethereum") do |n|
  n.display_name = "Ethereum"
end
sol = Network.find_or_create_by!(slug: "solana") do |n|
  n.display_name = "Solana"
end

Validator.find_or_create_by!(organization: org, network: eth, external_ref: "0xabc…validator") do |v|
  v.balance = "32000000000000000000" # 32 ETH in wei-style integer string
end
Validator.find_or_create_by!(organization: org, network: sol, external_ref: "Stake111…demo") do |v|
  v.balance = "100000000000" # lamports-style integer string
end

puts "Seeded org=#{org.id} api_key=demo-key"
