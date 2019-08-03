# frozen_string_literal: true

class RoadmapItem < ApplicationRecord
  MODELS_CATEGORY = 6

  has_paper_trail on: [:update], only: %i[release tasks inprogress completed]

  belongs_to :model, optional: true

  mount_uploader :store_image, StoreImageUploader

  def self.active
    where(active: true)
  end

  def last_version_changed_at
    versions.last&.created_at || updated_at
  end
end
