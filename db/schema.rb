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

ActiveRecord::Schema[8.0].define(version: 2025_08_29_190514) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chat_mcp_servers", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "name"
    t.string "transport_type"
    t.jsonb "config"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_chat_mcp_servers_on_chat_id"
  end

  create_table "chats", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "status"
    t.index ["status"], name: "index_chats_on_status"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "conversation_states", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "status"
    t.jsonb "pending_tools"
    t.jsonb "missing_params"
    t.jsonb "collected_params"
    t.text "original_message"
    t.jsonb "tool_results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_conversation_states_on_chat_id"
  end

  create_table "global_mcp_servers", force: :cascade do |t|
    t.string "name"
    t.string "transport_type"
    t.jsonb "config"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.text "content"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "prompt_tokens"
    t.integer "completion_tokens"
    t.integer "total_tokens"
    t.jsonb "usage_data", default: {}
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["total_tokens"], name: "index_messages_on_total_tokens"
    t.index ["usage_data"], name: "index_messages_on_usage_data", using: :gin
  end

  create_table "providers", force: :cascade do |t|
    t.string "name"
    t.string "provider_type"
    t.string "api_key"
    t.string "base_url"
    t.string "default_model"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_providers_on_user_id"
  end

  create_table "user_mcp_servers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "transport_type"
    t.jsonb "config"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_mcp_servers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "bluesky_did"
    t.string "bluesky_handle"
    t.string "display_name"
    t.string "avatar_url"
    t.boolean "is_admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.datetime "profile_updated_at"
  end

  add_foreign_key "chat_mcp_servers", "chats"
  add_foreign_key "chats", "users"
  add_foreign_key "conversation_states", "chats"
  add_foreign_key "messages", "chats"
  add_foreign_key "providers", "users"
  add_foreign_key "user_mcp_servers", "users"
end
