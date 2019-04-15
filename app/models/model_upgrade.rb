# frozen_string_literal: true

class ModelUpgrade < ApplicationRecord
  paginates_per 30

  has_many :upgrade_kits,
           dependent: :destroy
  has_many :models, through: :upgrade_kits
  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :upgrade_kits, allow_destroy: true

  before_save :update_slugs
  after_save :touch_shop_commodities
  after_save :touch_models

  def self.ordered_by_name
    order(name: :asc)
  end

  def self.visible
    where(hidden: false)
  end

  def self.active
    where(active: true)
  end

  private def touch_shop_commodities
    # rubocop:disable Rails/SkipsModelValidations
    shop_commodities.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private def touch_models
    # rubocop:disable Rails/SkipsModelValidations
    models.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
