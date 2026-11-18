# frozen_string_literal: true

class AddJurisdictionToLocations < ActiveRecord::Migration[8.1]
  def change
    %i[locations location_builds].each do |table|
      add_column table, :jurisdiction, :string
      add_column table, :lawful, :boolean
    end
  end
end
