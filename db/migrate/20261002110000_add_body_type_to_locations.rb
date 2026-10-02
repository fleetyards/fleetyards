# frozen_string_literal: true

# What kind of world a planet or moon is, where that changes how it is drawn:
# a gas or ice giant, a hollowed asteroid, a planet covered by one city.
class AddBodyTypeToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :body_type, :string
    add_column :location_builds, :body_type, :string
  end
end
