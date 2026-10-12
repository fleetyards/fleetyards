# frozen_string_literal: true

class CreateHangarPledgeItemModelPaints < ActiveRecord::Migration[8.1]
  def change
    create_table :hangar_pledge_item_model_paints, id: :uuid do |t|
      t.references :hangar_pledge_item, type: :uuid, null: false, index: false,
        foreign_key: {on_delete: :cascade}
      t.references :model_paint, type: :uuid, null: false, index: true,
        foreign_key: {on_delete: :cascade}
      t.timestamps
    end

    add_index :hangar_pledge_item_model_paints, [:hangar_pledge_item_id, :model_paint_id],
      unique: true, name: "index_hangar_pledge_item_model_paints_on_item_and_paint"
  end
end
