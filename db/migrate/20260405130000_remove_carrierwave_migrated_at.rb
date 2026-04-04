# frozen_string_literal: true

class RemoveCarrierwaveMigratedAt < ActiveRecord::Migration[8.0]
  def change
    %i[
      components
      fleets
      images
      imports
      manufacturers
      model_module_packages
      model_modules
      model_paints
      model_upgrades
      models
      users
    ].each do |table|
      remove_column table, :carrierwave_migrated_at, :datetime
    end
  end
end
