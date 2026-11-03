# frozen_string_literal: true

DEMO_API_KEY = "demo-key"

org = Organization.find_or_create_by!(name: "Demo Institution")
ApiKey.find_or_create_by!(organization: org, token_digest: ApiKey.digest(DEMO_API_KEY))

eth = Network.find_or_create_by!(slug: "ethereum") do |n|
  n.display_name = "Ethereum"
  n.symbol = "ETH"
  n.decimals = 18
end
sol = Network.find_or_create_by!(slug: "solana") do |n|
  n.display_name = "Solana"
  n.symbol = "SOL"
  n.decimals = 9
end

Validator.find_or_create_by!(organization: org, network: eth, external_ref: "0xabc…validator") do |v|
  v.balance = "32000000000000000000" # 32 ETH in wei
end
Validator.find_or_create_by!(organization: org, network: sol, external_ref: "Stake111…demo") do |v|
  v.balance = "100000000000" # 100 SOL in lamports
end

# Backfill 30 days of rewards so the console has data on first load.
sync_run = org.sync_runs.create!(kind: "rewards", from_date: 30.days.ago.to_date, to_date: Date.current)
SyncRewardsJob.perform_now(sync_run.id)

puts "Seeded org=#{org.id} api_key=#{DEMO_API_KEY} reward_events=#{org.reward_events.count}"
