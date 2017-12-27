class CreateTradeHubs < ActiveRecord::Migration[5.1]
  def change
    create_table :trade_hubs, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :name
      t.string :slug
      t.string :planet
      t.string :system
      t.string :station_type

      t.timestamps
    end
  end
end
