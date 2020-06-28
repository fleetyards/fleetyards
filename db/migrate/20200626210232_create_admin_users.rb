class CreateAdminUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :admin_users, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string "username", limit: 255, default: "", null: false
      t.string "email", limit: 255, default: "", null: false
      t.string "encrypted_password", limit: 255, default: "", null: false
      t.string "reset_password_token", limit: 255
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer "sign_in_count", default: 0, null: false
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string "current_sign_in_ip", limit: 255
      t.string "last_sign_in_ip", limit: 255
      t.integer "failed_attempts", default: 0, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["email"], name: "index_admin_users_on_email", unique: true
      t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
      t.index ["username"], name: "index_admin_users_on_username", unique: true
    end
  end
end
