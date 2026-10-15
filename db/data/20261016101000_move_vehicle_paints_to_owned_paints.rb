# frozen_string_literal: true

# A vehicle's one paint becomes a paint it owns, and the picture that paint gave
# it becomes the picture chosen in the gallery, so a ship without a picture of
# its own looks the same afterwards. A paint of another model -- left behind by
# a model change -- is neither.
#
# The pledge stays with the paint: a painted ship pledge is what sync matched
# it by.
class MoveVehiclePaintsToOwnedPaints < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO vehicle_paints (vehicle_id, model_paint_id, rsi_pledge_id, rsi_pledge_synced_at, created_at, updated_at)
      SELECT vehicles.id, vehicles.model_paint_id, vehicles.rsi_pledge_id, vehicles.rsi_pledge_synced_at, NOW(), NOW()
      FROM vehicles
      INNER JOIN model_paints
        ON model_paints.id = vehicles.model_paint_id
        AND model_paints.model_id = vehicles.model_id
      ON CONFLICT (vehicle_id, model_paint_id) DO NOTHING
    SQL

    execute <<~SQL.squish
      UPDATE vehicles
      SET model_paint_picture_id = vehicles.model_paint_id, updated_at = NOW()
      FROM model_paints
      WHERE model_paints.id = vehicles.model_paint_id
        AND model_paints.model_id = vehicles.model_id
        AND vehicles.model_image_id IS NULL
        AND NOT EXISTS (
          SELECT 1 FROM active_storage_attachments
          WHERE record_type = 'Vehicle' AND record_id = vehicles.id AND name = 'image'
        )
        AND EXISTS (
          SELECT 1 FROM active_storage_attachments
          WHERE record_type = 'ModelPaint' AND record_id = model_paints.id AND name = 'store_image'
        )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
