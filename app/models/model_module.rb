# frozen_string_literal: true

# == Schema Information
#
# Table name: model_modules
#
#  id                :uuid             not null, primary key
#  active            :boolean          default(TRUE)
#  description       :text
#  hidden            :boolean          default(TRUE)
#  name              :string
#  pledge_price      :decimal(15, 2)
#  production_status :string
#  slug              :string
#  store_image       :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  manufacturer_id   :uuid
#  model_id          :uuid
#
class ModelModule < ApplicationRecord
  paginates_per 30

  belongs_to :manufacturer, optional: true

  has_many :module_hardpoints,
    dependent: :destroy
  has_many :models, through: :module_hardpoints
  has_many :shop_commodities, as: :commodity_item, dependent: :destroy
  has_many :model_module_packge_items, dependent: :destroy
  has_many :model_module_packges, through: :model_module_packge_items

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :module_hardpoints, allow_destroy: true

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

  def sold_at
    shop_commodities.where.not(sell_price: nil).uniq { |item| item.shop.slug }
  end

  def bought_at
    shop_commodities.where.not(buy_price: nil).uniq { |item| item.shop.slug }
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
