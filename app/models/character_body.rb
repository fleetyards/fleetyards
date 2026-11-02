# frozen_string_literal: true

# A base body worn equipment is put on, in the frame every worn item's holo is
# exported in. Keyed by the folder the export publishes it under ("male"), so
# another body joins without a migration.
class CharacterBody < ApplicationRecord
  has_one_attached :holo

  validates :key, presence: true, uniqueness: true

  scope :with_holo, -> { joins(:holo_attachment).with_attached_holo.order(:key) }
end
