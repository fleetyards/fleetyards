class AddRsiHandleVerifiedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :rsi_handle_verified, :boolean, default: false, null: false
  end
end
