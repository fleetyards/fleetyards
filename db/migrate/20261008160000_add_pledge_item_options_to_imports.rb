# frozen_string_literal: true

class AddPledgeItemOptionsToImports < ActiveRecord::Migration[8.1]
  def change
    change_table :imports, bulk: true do |t|
      t.boolean :sync_paints, null: false, default: true
      t.boolean :sync_hangar_flair, null: false, default: true
    end
  end
end
