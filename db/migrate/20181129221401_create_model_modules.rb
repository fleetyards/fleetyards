class CreateModelModules < ActiveRecord::Migration[5.2]
  def change
    create_table :model_modules, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.uuid :manufacturer_id
      t.uuid :model_id
      t.boolean :active, default: true
      t.boolean :hidden, default: true
      t.string :production_status
      t.string :store_image

      t.timestamps
    end
  end
end
