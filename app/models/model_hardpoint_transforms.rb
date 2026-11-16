# frozen_string_literal: true

# Where on the flight hull holo each item port of a ship sits, as the ship views
# publish it.
#
# Touches the ship: its cargo holds are placed from the export, inside
# fragments keyed on the ship.
class ModelHardpointTransforms < ApplicationRecord
  belongs_to :model, touch: true
end
