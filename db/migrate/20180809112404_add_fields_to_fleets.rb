class AddFieldsToFleets < ActiveRecord::Migration[5.2]
  def change
    add_column :fleets, :banner, :string
    add_column :fleets, :background, :string
  end
end
