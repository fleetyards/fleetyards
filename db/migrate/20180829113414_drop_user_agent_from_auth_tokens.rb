class DropUserAgentFromAuthTokens < ActiveRecord::Migration[5.2]
  def up
    remove_column :auth_tokens, :user_agent
    remove_column :auth_tokens, :description
  end

  def down
    add_column :auth_tokens, :user_agent, :string
    add_column :auth_tokens, :description, :text
  end
end
