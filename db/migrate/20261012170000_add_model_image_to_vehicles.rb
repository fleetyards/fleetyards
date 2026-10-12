# frozen_string_literal: true

class AddModelImageToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_reference :vehicles, :model_image, type: :uuid, index: true,
      foreign_key: {to_table: :images, on_delete: :nullify}
  end
end
