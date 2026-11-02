class CreateOutfits < ActiveRecord::Migration[8.1]
  def change
    create_table :outfits, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.timestamps
    end
    add_index :outfits, [:user_id, :name], unique: true

    create_table :outfit_items, id: :uuid do |t|
      t.references :outfit, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.references :equipment, type: :uuid, null: false, foreign_key: true
      t.integer :slot, null: false
      t.timestamps
    end
    add_index :outfit_items, [:outfit_id, :slot], unique: true
  end
end
