# frozen_string_literal: true

class Shop < ApplicationRecord
  has_many :station_shops,
           dependent: :destroy
  has_many :stations,
           through: :station_shops

  validates :name, presence: true, uniqueness: true

  mount_uploader :store_image, StoreImageUploader

  before_save :update_slugs

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
