# frozen_string_literal: true

class ModelModule < ApplicationRecord
  paginates_per 30

  has_many :module_hardpoints,
           dependent: :destroy
  has_many :models, through: :module_hardpoints

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :module_hardpoints, allow_destroy: true
end
