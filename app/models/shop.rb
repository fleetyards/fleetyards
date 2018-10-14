# frozen_string_literal: true

class Shop < ApplicationRecord
  belongs_to :station
  has_many :shop_commodities, dependent: :destroy

  validates :name, :station, :shop_type, presence: true

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :shop_commodities, allow_destroy: true

  enum shop_type: %i[clothing armor weapons components armor_and_weapons superstore ships admin bar hospital salvage resources rental]

  before_save :update_slugs
  before_validation :update_shop_commodities

  def shop_type_label
    Shop.human_enum_name(:shop_type, shop_type)
  end

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end

  private def update_shop_commodities
    shop_commodities.each(&:set_commodity_item)
  end
end
