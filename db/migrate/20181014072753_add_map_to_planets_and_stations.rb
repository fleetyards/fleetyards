class AddMapToPlanetsAndStations < ActiveRecord::Migration[5.2]
  def change
    add_column :planets, :map, :string
    add_column :planets, :store_image, :string
    add_column :stations, :map, :string
    add_column :starsystems, :map, :string
    add_column :starsystems, :store_image, :string
  end
end
