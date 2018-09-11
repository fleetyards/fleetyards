class AddExpiresInToAuthTokens < ActiveRecord::Migration[5.2]
  def change
    add_column :auth_tokens, :expires_at, :datetime
    add_column :auth_tokens, :remember_me, :boolean, default: false
    add_column :auth_tokens, :user_agent, :string
  end
end
