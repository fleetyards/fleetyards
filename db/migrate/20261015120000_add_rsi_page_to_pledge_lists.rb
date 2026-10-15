# frozen_string_literal: true

class AddRsiPageToPledgeLists < ActiveRecord::Migration[8.1]
  def change
    add_column :buyback_pledges, :rsi_page, :integer
    add_column :hangar_pledge_items, :rsi_page, :integer
  end
end
