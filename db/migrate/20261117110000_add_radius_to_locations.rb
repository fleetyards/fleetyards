# frozen_string_literal: true

class AddRadiusToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :radius, :float
    add_column :location_builds, :radius, :float
  end
end
