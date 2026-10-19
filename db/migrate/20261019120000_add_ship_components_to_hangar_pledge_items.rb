# frozen_string_literal: true

class AddShipComponentsToHangarPledgeItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :hangar_pledge_items, :component, type: :uuid, index: true,
      foreign_key: {on_delete: :nullify}
    add_reference :hangar_pledge_items, :equipment, type: :uuid, index: true,
      foreign_key: {to_table: :equipment, on_delete: :nullify}

    add_column :imports, :sync_ship_components, :boolean, default: true, null: false
  end
end
