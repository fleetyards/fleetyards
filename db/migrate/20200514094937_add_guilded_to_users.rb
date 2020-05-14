class AddGuildedToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :guilded, :string
  end
end
