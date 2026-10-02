# frozen_string_literal: true

# Curated in admin rather than loaded: the colour a planet or moon is drawn in
# where no picture of it has been uploaded.
class AddColorToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :color, :string
  end
end
