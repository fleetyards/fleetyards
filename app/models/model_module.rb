# frozen_string_literal: true

# == Schema Information
#
# Table name: model_modules
#
#  id                :uuid             not null, primary key
#  active            :boolean          default(TRUE)
#  cargo             :decimal(15, 2)
#  cargo_holds       :string
#  description       :text
#  hidden            :boolean          default(TRUE)
#  name              :string
#  pledge_price      :decimal(15, 2)
#  production_status :string
#  sc_key            :string
#  slug              :string
#  store_image       :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  manufacturer_id   :uuid
#  model_id          :uuid
#
class ModelModule < ApplicationRecord
  paginates_per 30

  audited on: %i[update], only: %i[
    min_size max_size component_id cargo cargo_holds
  ]

  belongs_to :manufacturer, optional: true

  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true
  has_many :components, through: :hardpoints

  has_many :module_hardpoints,
    dependent: :destroy
  has_many :models, through: :module_hardpoints
  has_many :model_module_packge_items, dependent: :destroy
  has_many :model_module_packges, through: :model_module_packge_items

  has_many :item_prices, as: :item, dependent: :destroy

  serialize :cargo_holds, coder: YAML

  mount_uploader :store_image, StoreImageUploader

  accepts_nested_attributes_for :module_hardpoints, allow_destroy: true

  before_save :update_slugs

  after_save :touch_models

  def self.ransackable_attributes(auth_object = nil)
    [
      "active", "created_at", "description", "hidden", "id", "id_value", "manufacturer_id",
      "model_id", "name", "pledge_price", "production_status", "slug", "store_image", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    [
      "manufacturer", "model_module_packge_items", "model_module_packges", "models",
      "module_hardpoints", "shop_commodities"
    ]
  end

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
    item_prices.sell.order(price: :asc).uniq(&:location)
  end

  def bought_at
    item_prices.buy.order(price: :asc).uniq(&:location)
  end

  private def touch_models
    # rubocop:disable Rails/SkipsModelValidations
    models.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
