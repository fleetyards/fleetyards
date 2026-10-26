class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.references :item, type: :uuid, polymorphic: true, null: false, index: false
      t.references :item_price, type: :uuid, foreign_key: {on_delete: :nullify}
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end
    add_index :cart_items, [:user_id, :item_type, :item_id], unique: true
  end
end
