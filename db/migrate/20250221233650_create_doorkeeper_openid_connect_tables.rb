class CreateDoorkeeperOpenidConnectTables < ActiveRecord::Migration[7.2]
  def change
    create_table :oauth_openid_requests, id: :uuid do |t|
      t.references :access_grant, null: false, type: :uuid, index: true
      t.string :nonce, null: false
    end

    add_foreign_key(
      :oauth_openid_requests,
      :oauth_access_grants,
      column: :access_grant_id,
      on_delete: :cascade
    )
  end
end
