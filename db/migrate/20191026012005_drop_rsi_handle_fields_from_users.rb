class DropRsiHandleFieldsFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :rsi_handle, :string
    remove_column :users, :rsi_verified, :boolean, default: false
  end
end
