# frozen_string_literal: true

class AddDetailsToBuybackPledges < ActiveRecord::Migration[8.1]
  def change
    change_table :buyback_pledges, bulk: true do |t|
      t.boolean :available, null: false, default: true
      t.decimal :price, precision: 15, scale: 2
      t.integer :insurance_months
      t.boolean :lifetime_insurance, null: false, default: false
      t.datetime :details_synced_at
    end
  end
end
