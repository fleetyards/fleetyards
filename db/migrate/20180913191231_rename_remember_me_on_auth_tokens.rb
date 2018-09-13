class RenameRememberMeOnAuthTokens < ActiveRecord::Migration[5.2]
  def change
    rename_column :auth_tokens, :remember_me, :permanent
  end
end
