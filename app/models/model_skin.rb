# frozen_string_literal: true

class ModelSkin < ApplicationRecord
  paginates_per 30

  belongs_to :model, optional: true, touch: true

  mount_uploader :store_image, StoreImageUploader
  mount_uploader :rsi_store_image, StoreImageUploader

  before_save :update_slugs

  def self.visible
    where(hidden: false)
  end

  def self.active
    where(active: true)
  end

  private def update_slugs
    super
    self.rsi_slug = SlugHelper.generate_slug(rsi_name)
  end
end
