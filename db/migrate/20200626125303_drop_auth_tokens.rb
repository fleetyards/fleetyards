class DropAuthTokens < ActiveRecord::Migration[6.0]
  def up
    drop_table :auth_tokens
  end

  def down
    create_table "auth_tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid "user_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.datetime "expires_at"
      t.boolean "permanent", default: false
      t.string "client_key"
      t.string "browser"
      t.string "platform"
      t.index ["user_id"], name: "index_auth_tokens_on_user_id"
    end
  end
end
