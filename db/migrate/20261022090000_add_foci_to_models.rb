# frozen_string_literal: true

# `focus` stays until the release after this one: the release still serving
# while this migrates reads and writes it as a string.
class AddFociToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :foci, :string, array: true, default: [], null: false
    add_column :models, :stealth, :boolean, default: false, null: false
    add_column :models, :sc_role, :string
    add_index :models, :foci, using: :gin

    add_column :fleet_event_ships, :foci, :string, array: true, default: [], null: false
    add_column :mission_ships, :foci, :string, array: true, default: [], null: false
  end
end
