# frozen_string_literal: true

class AddModelSkinIdToVehicles < ActiveRecord::Migration[6.0]
  def change
    add_column :vehicles, :model_skin_id, :uuid
  end
end
