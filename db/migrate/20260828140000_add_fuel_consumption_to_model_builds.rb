# frozen_string_literal: true

# `fuel_consumption` is a game-file fact like the other 27 -- summed from the
# `fuel_burn_rate_per10_k_newton` of every thruster the loadout fits.
#
# It was missed when the table was created because it never went through
# `update_params`: the loader assigned it to the record directly, so a grep for
# what the loader writes did not find it.
class AddFuelConsumptionToModelBuilds < ActiveRecord::Migration[8.1]
  def change
    add_column :model_builds, :fuel_consumption, :decimal, precision: 15, scale: 2
  end
end
