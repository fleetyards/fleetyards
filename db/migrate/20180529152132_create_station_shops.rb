class CreateStationShops < ActiveRecord::Migration[5.2]
  def change
    create_table :station_shops, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid :station_id
      t.uuid :shop_id

      t.timestamps
    end
  end
end
