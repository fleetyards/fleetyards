# frozen_string_literal: true

# == Schema Information
#
# Table name: model_upgrades
#
#  id           :uuid             not null, primary key
#  active       :boolean          default(FALSE)
#  description  :text
#  hidden       :boolean          default(TRUE)
#  name         :string
#  pledge_price :decimal(15, 2)
#  slug         :string
#  store_image  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
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

  def self.ransackable_attributes(auth_object = nil)
    [
      "active", "created_at", "description", "hidden", "id", "id_value", "name", "pledge_price",
      "slug", "store_image", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["models", "shop_commodities", "upgrade_kits"]
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
