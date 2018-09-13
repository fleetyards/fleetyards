class AddClientKeyToAuthTokens < ActiveRecord::Migration[5.2]
  def up
    add_column :auth_tokens, :client_key, :string
    add_column :auth_tokens, :browser, :string
    add_column :auth_tokens, :platform, :string
    remove_column :auth_tokens, :user_agent
  end

  def down
    add_column :auth_tokens, :user_agent, :string
    remove_column :auth_tokens, :browser
    remove_column :auth_tokens, :platform
    remove_column :auth_tokens, :client_key
  end
end
