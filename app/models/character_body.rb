# frozen_string_literal: true

# A rigged base body worn equipment is put on. Keyed by the name the export
# lists it under ("male"), so another body joins without a migration. Every
# worn item's `rigged_<key>.glb` is skinned to the same skeleton in the same
# bind pose, and `animations` holds the clips that pose all of them by bone
# name; `clips` is what the export says about each.
class CharacterBody < ApplicationRecord
  has_one_attached :holo
  has_one_attached :animations

  validates :key, presence: true, uniqueness: true

  scope :with_holo, -> { joins(:holo_attachment).with_attached_holo.with_attached_animations.order(:key) }
end
