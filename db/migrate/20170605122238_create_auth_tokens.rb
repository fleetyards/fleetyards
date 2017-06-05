class CreateAuthTokens < ActiveRecord::Migration[5.1]
  def change
    create_table "auth_tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid "user_id", null: false
      t.string "token"
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "user_agent"
      t.integer "expires"
      t.index ["token"], name: "index_auth_tokens_on_token"
    end
  end
end
