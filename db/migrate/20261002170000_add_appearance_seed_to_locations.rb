# frozen_string_literal: true

# What the appearance seed last gave each place, so a field an admin cleared
# stays cleared until the seed itself changes.
class AddAppearanceSeedToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :appearance_seed, :jsonb, default: {}, null: false
  end
end
