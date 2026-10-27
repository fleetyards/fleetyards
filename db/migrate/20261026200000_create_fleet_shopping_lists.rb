class CreateFleetShoppingLists < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_shopping_lists, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :name, null: false
      t.text :description
      t.integer :visibility, null: false, default: 0
      t.timestamps
    end
    add_index :fleet_shopping_lists, "fleet_id, lower((name)::text)", unique: true,
      name: "index_fleet_shopping_lists_on_fleet_id_and_lower_name"

    create_table :fleet_shopping_list_items, id: :uuid do |t|
      t.references :fleet_shopping_list, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.references :item, type: :uuid, polymorphic: true, null: false, index: false
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end
    add_index :fleet_shopping_list_items, [:fleet_shopping_list_id, :item_type, :item_id], unique: true,
      name: "index_fleet_shopping_list_items_uniqueness"
    add_index :fleet_shopping_list_items, [:item_type, :item_id]
  end
end
