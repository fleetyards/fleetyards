# frozen_string_literal: true

class AddPositionToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :position, :float, array: true
    add_column :location_builds, :position, :float, array: true
  end
end
