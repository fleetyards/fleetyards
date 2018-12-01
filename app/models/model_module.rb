# frozen_string_literal: true

class ModelModule < ApplicationRecord
  paginates_per 30

  has_many :module_hardpoints,
           dependent: :destroy
  has_many :models, through: :module_hardpoints
  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :module_hardpoints, allow_destroy: true

  after_save :touch_shop_commodities

  def self.ordered_by_name
    order(name: :asc)
  end

  private def touch_shop_commodities
    # rubocop:disable Rails/SkipsModelValidations
    shop_commodities.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
