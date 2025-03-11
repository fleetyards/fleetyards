class ChangeTokenFieldsForDoorkeeperJwt < ActiveRecord::Migration[7.2]
  def up
    change_column :oauth_access_tokens, :token, :text, null: false
    change_column :oauth_access_tokens, :refresh_token, :text
  end

  def down
    change_column :oauth_access_tokens, :token, :string, limit: 512, null: false
    change_column :oauth_access_tokens, :refresh_token, :string, limit: 512
  end
end
