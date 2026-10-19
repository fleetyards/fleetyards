# frozen_string_literal: true

class AddInventoryItemToHangarPledgeItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :hangar_pledge_items, :inventory_item, type: :uuid, index: true,
      foreign_key: {on_delete: :nullify}
  end
end
