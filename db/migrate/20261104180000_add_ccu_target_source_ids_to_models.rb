class AddCcuTargetSourceIdsToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :ccu_target_source_ids, :uuid, array: true
  end
end
