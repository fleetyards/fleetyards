class CreateTradeRoutes < ActiveRecord::Migration[5.2]
  def change
    create_table :trade_routes, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.references :origin, type: :uuid
      t.references :origin_station, type: :uuid
      t.references :origin_celestial_object, type: :uuid
      t.references :origin_starsystem, type: :uuid
      t.references :destination, type: :uuid
      t.references :destination_station, type: :uuid
      t.references :destination_celestial_object, type: :uuid
      t.references :destination_starsystem, type: :uuid
      t.decimal :profit_per_unit, precision: 15, scale: 2
      t.decimal :profit_per_unit_percent, precision: 15, scale: 2

      t.timestamps
    end
  end
end
