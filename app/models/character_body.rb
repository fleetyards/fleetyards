# frozen_string_literal: true

# A rigged base body worn equipment is put on. Keyed by the name the export
# lists it under ("male"), so another body joins without a migration. Every
# worn item's `rigged_<key>.glb` is skinned to the same skeleton in the same
# bind pose, and `animations` holds the clips that pose all of them by bone
# name; `clips` is what the export says about each. `holo_textured` is the
# same body with the game's skin, eye, teeth and underwear textures, baked at
# `skin_tone`.
#
# The face library reshapes the body's head, eyes and teeth from a player's
# character file: `face_index` describes the arrays in `face_positions` and
# `face_normals`, and `face_library` names the build, which a character file
# saved against an older head list still blends with.
class CharacterBody < ApplicationRecord
  has_one_attached :holo
  has_one_attached :holo_textured
  has_one_attached :animations
  has_one_attached :face_index
  has_one_attached :face_positions
  has_one_attached :face_normals

  validates :key, presence: true, uniqueness: true

  scope :with_holo, -> {
    joins(:holo_attachment)
      .with_attached_holo.with_attached_holo_textured.with_attached_animations
      .with_attached_face_index.with_attached_face_positions.with_attached_face_normals
      .order(:key)
  }

  # All three files of one build, or nothing: a viewer cannot blend from part
  # of a library.
  def face_library?
    face_library.present? && face_index.attached? && face_positions.attached? && face_normals.attached?
  end
end
