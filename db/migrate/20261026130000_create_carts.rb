class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :name, null: false
      t.boolean :active, null: false, default: false
      t.timestamps
    end
    add_index :carts, [:user_id, :name], unique: true
    add_index :carts, :user_id, unique: true, where: "active", name: "index_carts_on_user_id_active"

    create_table :cart_items, id: :uuid do |t|
      t.references :cart, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.references :item, type: :uuid, polymorphic: true, null: false, index: false
      t.references :item_price, type: :uuid, foreign_key: {on_delete: :nullify}
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end
    add_index :cart_items, [:cart_id, :item_type, :item_id], unique: true
    add_index :cart_items, [:item_type, :item_id]
  end
end
