# frozen_string_literal: true

class AddVehiclePaints < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_paints, id: :uuid do |t|
      t.references :vehicle, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.references :model_paint, type: :uuid, null: false, index: true, foreign_key: {on_delete: :cascade}
      t.string :rsi_pledge_id
      t.datetime :rsi_pledge_synced_at
      t.timestamps
    end
    add_index :vehicle_paints, %i[vehicle_id model_paint_id], unique: true

    add_reference :vehicles, :model_paint_picture, type: :uuid, index: true,
      foreign_key: {to_table: :model_paints, on_delete: :nullify}
    add_check_constraint :vehicles, "num_nonnulls(model_image_id, model_paint_picture_id) <= 1",
      name: "vehicles_one_gallery_picture"
  end
end
