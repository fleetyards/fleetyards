# frozen_string_literal: true

class CreateModelPositions < ActiveRecord::Migration[7.2]
  def change
    create_table :model_positions, id: :uuid do |t|
      t.uuid :model_id, null: false
      t.string :name, null: false
      t.integer :position_type, null: false
      t.uuid :hardpoint_id
      t.integer :source, null: false, default: 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :model_positions, :model_id
    add_index :model_positions, %i[model_id hardpoint_id], unique: true, where: "hardpoint_id IS NOT NULL"

    add_foreign_key :model_positions, :models
    add_foreign_key :model_positions, :hardpoints

    add_column :models, :positions_need_curation, :boolean, default: false
  end
end
