class AddRsiVerifiedFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :rsi_verified, :boolean, default: false
    add_column :users, :rsi_verification_token, :string
  end
end
