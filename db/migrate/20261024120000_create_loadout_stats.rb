# frozen_string_literal: true

class CreateLoadoutStats < ActiveRecord::Migration[8.1]
  def change
    create_table :loadout_stats, id: :uuid do |t|
      t.string :fitting_type, null: false
      t.uuid :fitting_id, null: false
      t.string :environment, null: false
      t.string :version, null: false
      t.integer :max_weapon_size
      t.jsonb :weapon_sizes, null: false, default: {}
      t.timestamps
    end

    add_index :loadout_stats, %i[fitting_type fitting_id environment], unique: true, name: "index_loadout_stats_on_fitting_and_environment"
  end
end
