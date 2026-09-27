# frozen_string_literal: true

class CreateTerminals < ActiveRecord::Migration[8.1]
  def change
    create_table :terminals, id: :uuid do |t|
      t.integer :uex_id, null: false
      t.string :name, null: false
      t.string :nickname
      t.string :display_name
      t.string :code
      t.string :star_system
      t.string :planet
      t.string :orbit
      t.string :moon
      t.string :space_station
      t.string :city
      t.string :outpost
      t.integer :max_container_size
      t.boolean :has_freight_elevator, null: false, default: false
      t.boolean :has_loading_dock, null: false, default: false
      t.boolean :has_docking_port, null: false, default: false
      t.boolean :player_owned, null: false, default: false
      t.boolean :available, null: false, default: true
      t.string :contact_url
      t.datetime :source_updated_at

      t.timestamps
    end

    add_index :terminals, :uex_id, unique: true
    add_index :terminals, :star_system
  end
end
