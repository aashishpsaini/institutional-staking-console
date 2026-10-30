class CreateStakingConsoleSchema < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :api_keys do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :token, null: false
      t.timestamps
    end
    add_index :api_keys, :token, unique: true

    create_table :networks do |t|
      t.string :slug, null: false
      t.string :display_name, null: false
      t.timestamps
    end
    add_index :networks, :slug, unique: true

    create_table :validators do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :network, null: false, foreign_key: true
      t.string :external_ref, null: false
      t.string :balance, null: false, default: "0"
      t.timestamps
    end
    add_index :validators, %i[organization_id network_id external_ref], unique: true, name: "idx_validators_org_network_ref"

    create_table :reward_events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :network, null: false, foreign_key: true
      t.string :validator_ref
      t.date :reward_date, null: false
      t.string :amount, null: false
      t.string :external_id, null: false
      t.timestamps
    end
    add_index :reward_events, :external_id, unique: true
    add_index :reward_events, %i[organization_id network_id reward_date], name: "idx_rewards_org_network_date"

    create_table :stake_operations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :network, null: false, foreign_key: true
      t.string :action, null: false
      t.string :amount, null: false
      t.string :status, null: false, default: "pending"
      t.string :external_id
      t.text :error_message
      t.timestamps
    end
    add_index :stake_operations, %i[organization_id created_at]

    create_table :sync_runs do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :kind, null: false
      t.datetime :finished_at
      t.string :status, null: false, default: "running"
      t.timestamps
    end
  end
end
