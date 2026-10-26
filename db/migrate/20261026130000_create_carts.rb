class CreateCarts < ActiveRecord::Migration[8.1]
  def up
    create_table :carts, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :name, null: false
      t.boolean :active, null: false, default: false
      t.timestamps
    end
    add_index :carts, [:user_id, :name], unique: true
    add_index :carts, :user_id, unique: true, where: "active", name: "index_carts_on_user_id_active"

    add_reference :cart_items, :cart, type: :uuid, foreign_key: {on_delete: :cascade}, index: false

    execute <<~SQL
      INSERT INTO carts (user_id, name, active, created_at, updated_at)
      SELECT DISTINCT user_id, 'Shopping list', true, NOW(), NOW() FROM cart_items
    SQL
    execute <<~SQL
      UPDATE cart_items SET cart_id = carts.id FROM carts WHERE carts.user_id = cart_items.user_id
    SQL

    change_column_null :cart_items, :cart_id, false
    remove_index :cart_items, [:user_id, :item_type, :item_id]
    remove_reference :cart_items, :user, type: :uuid, foreign_key: {on_delete: :cascade}, index: false
    add_index :cart_items, [:cart_id, :item_type, :item_id], unique: true
  end

  def down
    add_reference :cart_items, :user, type: :uuid, foreign_key: {on_delete: :cascade}, index: false

    execute <<~SQL
      UPDATE cart_items SET user_id = carts.user_id FROM carts WHERE carts.id = cart_items.cart_id
    SQL
    execute <<~SQL
      DELETE FROM cart_items USING carts WHERE carts.id = cart_items.cart_id AND NOT carts.active
    SQL

    change_column_null :cart_items, :user_id, false
    remove_index :cart_items, [:cart_id, :item_type, :item_id]
    remove_reference :cart_items, :cart, type: :uuid, foreign_key: {on_delete: :cascade}, index: false
    add_index :cart_items, [:user_id, :item_type, :item_id], unique: true
    drop_table :carts
  end
end
