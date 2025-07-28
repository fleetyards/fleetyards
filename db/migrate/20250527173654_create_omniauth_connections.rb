class CreateOmniauthConnections < ActiveRecord::Migration[7.2]
  def change
    create_table :omniauth_connections, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :uid, null: false
      t.integer :provider, null: false
      t.jsonb :auth_payload

      t.timestamps
    end
  end
end
