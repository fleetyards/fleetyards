class CreateVehicleAdditions < ActiveRecord::Migration[5.1]
  def change
    create_table :vehicle_additions, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :beam
      t.string :length
      t.string :height
      t.string :mass
      t.string :cargo
      t.string :crew

      t.uuid "ship_id", null: false

      t.timestamps
    end
  end
end
