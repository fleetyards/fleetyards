class AddAlternativeNamesToVehicles < ActiveRecord::Migration[6.1]
  def change
    add_column :vehicles, :alternative_names, :string
  end
end
