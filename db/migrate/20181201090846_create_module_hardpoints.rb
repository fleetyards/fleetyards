class CreateModuleHardpoints < ActiveRecord::Migration[5.2]
  def change
    create_table :module_hardpoints do |t|
      t.uuid :model_id
      t.uuid :model_module_id

      t.timestamps
    end
  end
end
