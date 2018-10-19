class AddBaseModelIdToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :base_model_id, :uuid
    add_index :models, :base_model_id
  end
end
