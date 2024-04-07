# frozen_string_literal: true

# == Schema Information
#
# Table name: model_paints
#
#  id                      :uuid             not null, primary key
#  active                  :boolean          default(TRUE)
#  angled_view             :string
#  angled_view_height      :integer
#  angled_view_width       :integer
#  description             :string
#  fleetchart_image        :string
#  fleetchart_image_height :integer
#  fleetchart_image_width  :integer
#  hidden                  :boolean          default(TRUE)
#  last_pledge_price       :decimal(15, 2)
#  last_updated_at         :datetime
#  name                    :string
#  on_sale                 :boolean          default(FALSE)
#  pledge_price            :decimal(15, 2)
#  production_note         :string
#  production_status       :string
#  rsi_description         :string
#  rsi_name                :string
#  rsi_slug                :string
#  rsi_store_image         :string
#  rsi_store_url           :string
#  side_view               :string
#  side_view_height        :integer
#  side_view_width         :integer
#  slug                    :string
#  store_image             :string
#  store_images_updated_at :datetime
#  store_url               :string
#  top_view                :string
#  top_view_height         :integer
#  top_view_width          :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_id                :uuid
#  rsi_id                  :integer
#
class ModelPaint < ApplicationRecord
  paginates_per 30

  belongs_to :model, optional: true, touch: true, counter_cache: true

  has_many :vehicles, dependent: :nullify
  has_many :item_prices, as: :item, dependent: :destroy

  mount_uploader :store_image, StoreImageUploader
  mount_uploader :rsi_store_image, StoreImageUploader
  mount_uploader :fleetchart_image, FleetchartImageUploader
  mount_uploader :top_view, FleetchartImageUploader
  mount_uploader :side_view, FleetchartImageUploader
  mount_uploader :angled_view, FleetchartImageUploader

  def self.ransackable_attributes(auth_object = nil)
    [
      "active", "angled_view", "angled_view_height", "angled_view_width", "created_at",
      "description", "fleetchart_image", "fleetchart_image_height", "fleetchart_image_width",
      "hidden", "id", "id_value", "last_pledge_price", "last_updated_at", "model_id", "name",
      "on_sale", "pledge_price", "production_note", "production_status", "rsi_description",
      "rsi_id", "rsi_name", "rsi_slug", "rsi_store_image", "rsi_store_url", "side_view",
      "side_view_height", "side_view_width", "slug", "store_image", "store_images_updated_at",
      "store_url", "top_view", "top_view_height", "top_view_width", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["model", "shop_commodities", "vehicles"]
  end

  before_save :update_slugs

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

  def name_with_model
    "#{model.name} - #{name}"
  end

  private def update_slugs
    super
    self.rsi_slug = SlugHelper.generate_slug(rsi_name)
  end
end
