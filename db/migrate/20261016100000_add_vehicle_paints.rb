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

    # The picture picked for the ship: a model gallery `Image`, or a `ModelPaint`
    # whose store image it shows. Beside an uploaded image, which wins.
    add_reference :vehicles, :picture, type: :uuid, polymorphic: true, index: true
  end
end
