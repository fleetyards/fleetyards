# frozen_string_literal: true

class AddFacilitiesToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :location_builds, :facilities, :jsonb
    add_column :locations, :facilities, :jsonb
  end
end
