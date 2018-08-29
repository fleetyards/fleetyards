class AddKeyToAuthTokens < ActiveRecord::Migration[5.2]
  def change
    add_column :auth_tokens, :key, :string
  end
end
