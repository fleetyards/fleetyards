# frozen_string_literal: true

class AddShipModuleToHangarPledgeItems < ActiveRecord::Migration[8.1]
  def change
    add_column :hangar_pledge_items, :ship_module, :boolean, default: false, null: false
  end
end
