class CreateModelModulePackages < ActiveRecord::Migration[6.1]
  def change
    create_table :model_module_packages, id: :uuid do |t|
      t.uuid :model_id
      t.string :name
      t.string :slug
      t.text :description
      t.string :store_image
      t.boolean :hidden, default: true
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
