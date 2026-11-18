# frozen_string_literal: true

class CreateLocationSurfaces < ActiveRecord::Migration[8.1]
  def change
    create_table :location_surfaces, id: :uuid do |t|
      t.references :location, type: :uuid, null: false, foreign_key: true, index: false
      t.string :environment, null: false

      t.timestamps
    end

    add_index :location_surfaces, [:location_id, :environment], unique: true
  end
end
