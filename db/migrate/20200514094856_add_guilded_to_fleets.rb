class AddGuildedToFleets < ActiveRecord::Migration[6.0]
  def change
    add_column :fleets, :guilded, :string
  end
end
