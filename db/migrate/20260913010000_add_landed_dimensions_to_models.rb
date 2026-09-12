# frozen_string_literal: true

# A ship has more than one set of dimensions, and which one matters depends on
# the question. Measured from the unscaled exports:
#
#   Pisces in flight   12.81 x 10.22 x 3.01
#   Pisces landed      12.81 x  8.65 x 3.44   wings folded, gear down
#
# The hull is the same length either way, but it is narrower and taller once it
# is standing on something. A berth has to take the landed figures, because that
# is the state a ship is in inside a hangar -- and `Dock#fits?` compares against
# `height`, which today is the flying one.
#
# Separate from `extended_*`, which is a third state again: the Ursa with its
# turret raised, the Hull C with its spindle out. Those unfold; this one lands.
class AddLandedDimensionsToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :landed_length, :decimal, precision: 15, scale: 2
    add_column :models, :landed_beam, :decimal, precision: 15, scale: 2
    add_column :models, :landed_height, :decimal, precision: 15, scale: 2
  end
end
