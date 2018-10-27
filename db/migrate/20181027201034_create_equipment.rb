class CreateEquipment < ActiveRecord::Migration[5.2]
  def change
    create_table :equipment, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.string :name
      t.string :slug
      t.string :store_image
      t.integer :equipment_type
      t.boolean :hidden, default: true
      t.text :description

      t.timestamps
    end
  end
end
