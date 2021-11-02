class CreateModelModulePackageItems < ActiveRecord::Migration[6.1]
  def change
    create_table :model_module_package_items, id: :uuid do |t|
      t.uuid :model_module_package_id
      t.uuid :model_module_id

      t.timestamps
    end
  end
end
