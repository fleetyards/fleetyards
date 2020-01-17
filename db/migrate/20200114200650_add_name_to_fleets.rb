class AddNameToFleets < ActiveRecord::Migration[5.2]
  def change
    add_column :fleets, :name, :string
  end
end
