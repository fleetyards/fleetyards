# frozen_string_literal: true

class AddCarrierwaveMigratedAtToModels < ActiveRecord::Migration[7.2]
  def change
    tables = %i[
      models
      model_paints
      model_module_packages
      fleets
      images
      components
      model_modules
      model_upgrades
      manufacturers
      users
      imports
    ]

    tables.each do |table|
      add_column table, :carrierwave_migrated_at, :datetime, null: true
    end
  end
end
