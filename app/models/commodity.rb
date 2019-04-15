# frozen_string_literal: true

class Commodity < ApplicationRecord
  has_many :trade_commodities,
           dependent: :nullify
  has_many :trade_hubs,
           through: :trade_commodities

  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  def self.ordered_by_name
    order(name: :asc)
  end
end
