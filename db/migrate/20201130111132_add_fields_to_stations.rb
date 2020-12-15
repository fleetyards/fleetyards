class AddFieldsToStations < ActiveRecord::Migration[6.0]
  def change
    add_column :stations, :classification, :integer
    add_column :stations, :habitable, :boolean, default: true
  end
end
