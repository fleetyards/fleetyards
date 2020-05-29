# frozen_string_literal: true

class ModelPaint < ApplicationRecord
  paginates_per 30

  belongs_to :model, optional: true, touch: true

  has_many :vehicles, dependent: :nullify

  mount_uploader :store_image, StoreImageUploader
  mount_uploader :rsi_store_image, StoreImageUploader
  mount_uploader :fleetchart_image, FleetchartImageUploader

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
