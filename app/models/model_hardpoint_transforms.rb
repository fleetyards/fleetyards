# frozen_string_literal: true

# Where on the flight hull holo each item port of a ship sits, as the ship views
# publish it.
class ModelHardpointTransforms < ApplicationRecord
  belongs_to :model
end
