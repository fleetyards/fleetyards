# frozen_string_literal: true

# Owned paints and the picked `picture` replaced them, and the release before
# this one already ignores both.
class RemoveReplacedPictureColumnsFromVehicles < ActiveRecord::Migration[8.1]
  def change
    remove_index :vehicles, %i[model_paint_id hidden wanted loaner],
      name: "index_vehicles_on_model_paint_id_where_painted", where: "(model_paint_id IS NOT NULL)"
    remove_column :vehicles, :model_paint_id, :uuid

    remove_foreign_key :vehicles, :images, column: :model_image_id, on_delete: :nullify
    remove_index :vehicles, :model_image_id
    remove_column :vehicles, :model_image_id, :uuid
  end
end
