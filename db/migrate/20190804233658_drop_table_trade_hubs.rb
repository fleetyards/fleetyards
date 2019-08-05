class DropTableTradeHubs < ActiveRecord::Migration[5.2]
  def up
    drop_table :trade_hubs
  end

  def down
    create_table "trade_hubs", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string "name"
      t.string "slug"
      t.string "planet"
      t.string "system"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "station_type"
    end
  end
end
