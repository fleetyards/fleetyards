# frozen_string_literal: true

# Fills in the fact the build table was created without. Every model build of
# every environment gets the value its row carries, which is what the loader
# wrote there.
#
# Only rows that have none: a build written since the column landed already
# carries its own value, and overwriting it with the row's would undo a later
# load.
class BackfillModelBuildFuelConsumption < ActiveRecord::Migration[8.1]
  def up
    ModelBuild.where(fuel_consumption: nil).includes(:model).find_each do |build|
      value = build.model&.read_attribute(:fuel_consumption)
      next if value.blank?

      build.update_columns(fuel_consumption: value)
    end
  end

  def down
    ModelBuild.update_all(fuel_consumption: nil)
  end
end
