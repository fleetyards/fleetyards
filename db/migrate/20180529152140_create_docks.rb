class CreateDocks < ActiveRecord::Migration[5.2]
  def change
    create_table :docks, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.integer :dock_type
      t.uuid :station_id
      t.string :name
      t.integer :max_ship_size
      t.integer :min_ship_size

      t.timestamps
    end
  end
end
