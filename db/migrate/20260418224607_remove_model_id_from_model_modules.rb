class RemoveModelIdFromModelModules < ActiveRecord::Migration[8.1]
  def change
    remove_column :model_modules, :model_id, :uuid
  end
end
