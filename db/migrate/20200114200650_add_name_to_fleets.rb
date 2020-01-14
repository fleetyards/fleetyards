class AddNameToFleets < ActiveRecord::Migration[5.2]
  def up
    add_column :fleets, :name, :string
  end
end
