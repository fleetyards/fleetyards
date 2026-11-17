# frozen_string_literal: true

class CreateStarSystemsAndJumpTunnels < ActiveRecord::Migration[8.1]
  def change
    create_table :star_systems, id: :uuid do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.float :position, array: true, null: false
      t.string :system_type
      t.text :affiliations, array: true, default: [], null: false
      t.boolean :in_game, default: false, null: false

      t.timestamps

      t.index :code, unique: true
    end

    create_table :jump_tunnels, id: :uuid do |t|
      t.references :entry_system, type: :uuid, null: false, foreign_key: {to_table: :star_systems, on_delete: :cascade}
      t.references :exit_system, type: :uuid, null: false, foreign_key: {to_table: :star_systems, on_delete: :cascade}
      t.string :size
      t.boolean :bidirectional, default: true, null: false

      t.timestamps

      t.index [:entry_system_id, :exit_system_id], unique: true
    end
  end
end
