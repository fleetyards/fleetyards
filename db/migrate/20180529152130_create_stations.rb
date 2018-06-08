class CreateStations < ActiveRecord::Migration[5.2]
  def change
    create_table :stations, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :name
      t.string :slug
      t.uuid :planet_id
      t.integer :station_type

      t.timestamps
    end
  end
end
