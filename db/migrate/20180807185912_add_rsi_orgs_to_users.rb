class AddRsiOrgsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :rsi_orgs, :string
  end
end
