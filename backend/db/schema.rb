# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_01_01_000000) do
  create_table "api_keys", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_api_keys_on_organization_id"
    t.index ["token"], name: "index_api_keys_on_token", unique: true
  end

  create_table "networks", force: :cascade do |t|
    t.string "slug", null: false
    t.string "display_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_networks_on_slug", unique: true
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reward_events", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "network_id", null: false
    t.string "validator_ref"
    t.date "reward_date", null: false
    t.string "amount", null: false
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_reward_events_on_external_id", unique: true
    t.index ["network_id"], name: "index_reward_events_on_network_id"
    t.index ["organization_id", "network_id", "reward_date"], name: "idx_rewards_org_network_date"
    t.index ["organization_id"], name: "index_reward_events_on_organization_id"
  end

  create_table "stake_operations", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "network_id", null: false
    t.string "action", null: false
    t.string "amount", null: false
    t.string "status", default: "pending", null: false
    t.string "external_id"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["network_id"], name: "index_stake_operations_on_network_id"
    t.index ["organization_id", "created_at"], name: "index_stake_operations_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_stake_operations_on_organization_id"
  end

  create_table "sync_runs", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "kind", null: false
    t.datetime "finished_at"
    t.string "status", default: "running", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_sync_runs_on_organization_id"
  end

  create_table "validators", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "network_id", null: false
    t.string "external_ref", null: false
    t.string "balance", default: "0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["network_id"], name: "index_validators_on_network_id"
    t.index ["organization_id", "network_id", "external_ref"], name: "idx_validators_org_network_ref", unique: true
    t.index ["organization_id"], name: "index_validators_on_organization_id"
  end

  add_foreign_key "api_keys", "organizations"
  add_foreign_key "reward_events", "networks"
  add_foreign_key "reward_events", "organizations"
  add_foreign_key "stake_operations", "networks"
  add_foreign_key "stake_operations", "organizations"
  add_foreign_key "sync_runs", "organizations"
  add_foreign_key "validators", "networks"
  add_foreign_key "validators", "organizations"
end
