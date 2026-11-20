# frozen_string_literal: true

class TrespassAreasAndArmisticeSpheresOnLocations < ActiveRecord::Migration[8.1]
  def change
    %i[locations location_builds].each do |table|
      rename_column table, :restricted_areas, :trespass_areas
      add_column table, :armistice_sphere, :jsonb
    end
  end
end
