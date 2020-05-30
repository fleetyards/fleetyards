# frozen_string_literal: true

class AddCounterCachesToModels < ActiveRecord::Migration[6.0]
  def change
    add_column :models, :model_paints_count, :integer, default: 0
    add_column :models, :images_count, :integer, default: 0
    add_column :models, :videos_count, :integer, default: 0
    add_column :models, :upgrade_kits_count, :integer, default: 0
    add_column :models, :module_hardpoints_count, :integer, default: 0
    add_column :stations, :images_count, :integer, default: 0
  end
end
