# frozen_string_literal: true

# A vehicle's one paint becomes a paint it owns, and its picture becomes the
# picked `picture`: the gallery image it had picked, else the store image its
# paint gave it, so every ship looks the same afterwards. A paint of another
# model -- left behind by a model change -- is neither owned nor shown.
#
# No pledge is carried over: the hull's pledge is not necessarily the one the
# paint came with, as a paint applied by hand shows. The next sync stamps the
# paints that did come with one.
class MoveVehiclePaintsAndPictures < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO vehicle_paints (vehicle_id, model_paint_id, created_at, updated_at)
      SELECT vehicles.id, vehicles.model_paint_id, NOW(), NOW()
      FROM vehicles
      INNER JOIN model_paints
        ON model_paints.id = vehicles.model_paint_id
        AND model_paints.model_id = vehicles.model_id
      ON CONFLICT (vehicle_id, model_paint_id) DO NOTHING
    SQL

    execute <<~SQL.squish
      UPDATE vehicles
      SET picture_type = 'Image', picture_id = vehicles.model_image_id, updated_at = NOW()
      FROM images
      WHERE images.id = vehicles.model_image_id
        AND images.gallery_type = 'Model'
        AND images.gallery_id = vehicles.model_id
    SQL

    execute <<~SQL.squish
      UPDATE vehicles
      SET picture_type = 'ModelPaint', picture_id = vehicles.model_paint_id, updated_at = NOW()
      FROM model_paints
      WHERE model_paints.id = vehicles.model_paint_id
        AND model_paints.model_id = vehicles.model_id
        AND vehicles.picture_id IS NULL
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
