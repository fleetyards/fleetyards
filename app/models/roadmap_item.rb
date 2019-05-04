# frozen_string_literal: true

class RoadmapItem < ApplicationRecord
  MODELS_CATEGORY = 6

  has_paper_trail on: [:update], only: %i[release tasks inprogress completed]

  belongs_to :model, optional: true

  mount_uploader :store_image, StoreImageUploader
end
