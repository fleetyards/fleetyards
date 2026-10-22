class AddPlaqueLocaleToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :plaque_locale, :string
  end
end
