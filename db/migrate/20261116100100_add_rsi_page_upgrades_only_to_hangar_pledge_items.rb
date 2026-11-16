# frozen_string_literal: true

class AddRsiPageUpgradesOnlyToHangarPledgeItems < ActiveRecord::Migration[8.1]
  def change
    add_column :hangar_pledge_items, :rsi_page_upgrades_only, :boolean, default: false, null: false
  end
end
