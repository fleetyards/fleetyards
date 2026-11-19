# frozen_string_literal: true

class AddAmenitiesToLocations < ActiveRecord::Migration[8.1]
  def change
    %i[locations location_builds].each do |table|
      add_column table, :amenities, :string, array: true, default: [], null: false
    end
  end
end
