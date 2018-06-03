class AddFieldsToStations < ActiveRecord::Migration[5.2]
  def change
    add_column :stations, :hidden, :boolean, default: false
    add_column :stations, :store_image, :string
  end
end
