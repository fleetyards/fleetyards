# frozen_string_literal: true

class ModelModule < ApplicationRecord
  paginates_per 30

  belongs_to :model
  belongs_to :manufacturer, required: false

  mount_uploader :store_image, StoreImageUploader
end
