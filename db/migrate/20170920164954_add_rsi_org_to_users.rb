class AddRsiOrgToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :rsi_org, :string
  end
end
