# frozen_string_literal: true

class AddZonesToLocations < ActiveRecord::Migration[8.1]
  def change
    %i[locations location_builds].each do |table|
      add_column table, :armistice, :string
      add_column table, :restricted_areas, :boolean
    end
  end
end
