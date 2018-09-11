class DropFieldsFromAuthTokens < ActiveRecord::Migration[5.2]
  def up
    remove_column :auth_tokens, :key
    remove_column :auth_tokens, :token
    remove_column :auth_tokens, :expires
  end

  def down
    add_column :auth_tokens, :key, :string
    add_column :auth_tokens, :token, :string
    add_column :auth_tokens, :expires, :integer
  end
end
