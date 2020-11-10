class AddFieldsToStations < ActiveRecord::Migration[6.0]
  def change
    add_column :stations, :cargo_hub, :boolean
    add_column :stations, :refinary, :boolean
  end
end
