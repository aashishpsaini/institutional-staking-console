class HardenStakingConsoleSchema < ActiveRecord::Migration[7.1]
  def up
    # Network metadata so clients never hardcode token decimals/symbols.
    add_column :networks, :symbol, :string
    add_column :networks, :decimals, :integer
    execute "UPDATE networks SET symbol = 'ETH', decimals = 18 WHERE slug = 'ethereum'"
    execute "UPDATE networks SET symbol = 'SOL', decimals = 9 WHERE slug = 'solana'"

    # API keys: store only a SHA-256 digest of the token, support revocation.
    add_column :api_keys, :token_digest, :string
    add_column :api_keys, :revoked_at, :datetime
    add_column :api_keys, :last_used_at, :datetime
    execute_backfill_api_key_digests
    change_column_null :api_keys, :token_digest, false
    remove_index :api_keys, :token
    remove_column :api_keys, :token
    add_index :api_keys, :token_digest, unique: true

    # Reward external ids are only unique within a tenant.
    remove_index :reward_events, :external_id
    add_index :reward_events, %i[organization_id external_id], unique: true

    # Client-supplied Idempotency-Key prevents duplicate stake submissions.
    add_column :stake_operations, :idempotency_key, :string
    add_index :stake_operations, %i[organization_id idempotency_key], unique: true

    # Sync runs carry enough state for the UI to poll and for operators to debug.
    add_column :sync_runs, :from_date, :date
    add_column :sync_runs, :to_date, :date
    add_column :sync_runs, :started_at, :datetime
    add_column :sync_runs, :records_upserted, :integer, null: false, default: 0
    add_column :sync_runs, :error_message, :text
    change_column_default :sync_runs, :status, from: "running", to: "queued"
    add_index :sync_runs, %i[organization_id kind finished_at]
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "API key tokens cannot be recovered from their digests"
  end

  private
    def execute_backfill_api_key_digests
      select_rows("SELECT id, token FROM api_keys").each do |id, token|
        digest = Digest::SHA256.hexdigest(token)
        execute "UPDATE api_keys SET token_digest = #{quote(digest)} WHERE id = #{Integer(id)}"
      end
    end
end
