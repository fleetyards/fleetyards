class CreateAuthTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :auth_tokens, id: :uuid do |t|
      t.references :user, type: :uuid, foreign_key: true
      t.string :token, index: { unique: true }
      t.datetime :expired_at
      t.string :description

      t.timestamps
    end
  end
end
