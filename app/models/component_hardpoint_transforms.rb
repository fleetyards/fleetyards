# frozen_string_literal: true

# Where on a module's hull holo each of its item ports sits, and how its doors
# open, as the item views publish them beside the module's holo.
class ComponentHardpointTransforms < ApplicationRecord
  belongs_to :component
end
