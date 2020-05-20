class ChangeModelSkinsToModelPaints < ActiveRecord::Migration[6.0]
  def self.up
    rename_table :model_skins, :model_paints
    rename_column :vehicles, :model_skin_id, :model_paint_id
  end

  def self.down
    rename_column :vehicles, :model_paint_id, :model_skin_id
    rename_table :model_paints, :model_skins
  end
end
