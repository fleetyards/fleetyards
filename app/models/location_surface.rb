# frozen_string_literal: true

# How the game draws a planet, moon or star on its starmap, per environment:
# the surface texture, the terrain's elevation and cloud cover, and on a body
# the game paints with its newer planet engine the colour of the ground.
#
# One per environment rather than per build: the images rarely change between
# patches and are tens of megabytes a system, and builds are pruned with
# `delete_all`, which would leave every attachment behind. Live and PTU each
# keep their own, so a body that looks different on PTU can show it.
class LocationSurface < ApplicationRecord
  belongs_to :location

  has_one_attached :texture
  has_one_attached :elevation
  has_one_attached :clouds
  has_one_attached :ground

  ROLES = %i[texture elevation clouds ground].freeze

  validates :environment, presence: true, uniqueness: {scope: :location_id}
end
