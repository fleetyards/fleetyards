class CreateOauthConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_connections, id: :uuid do |t|
      t.string :provider
      t.string :uid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
