# frozen_string_literal: true

# What can be mined, harvested or hunted on a body, lifted out of its
# description by the starmap parser: kind and items, each with an optional
# note -- "Janalite", "Caves only".
class AddResourcesToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :resources, :jsonb, null: false, default: []
    add_column :location_builds, :resources, :jsonb, null: false, default: []
  end
end
