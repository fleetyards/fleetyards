# frozen_string_literal: true

# == Schema Information
#
# Table name: model_paints
#
#  id                      :uuid             not null, primary key
#  active                  :boolean          default(TRUE)
#  description             :string
#  hidden                  :boolean          default(TRUE)
#  last_updated_at         :datetime
#  name                    :string
#  on_sale                 :boolean          default(FALSE)
#  pledge_price            :decimal(15, 2)
#  production_note         :string
#  production_status       :string
#  rsi_description         :string
#  rsi_name                :string
#  rsi_slug                :string
#  rsi_store_url           :string
#  slug                    :string
#  store_images_updated_at :datetime
#  store_url               :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_id                :uuid
#  rsi_id                  :integer
#
class ModelPaint < ApplicationRecord
  include ActiveStorageVariants

  paginates_per 30

  belongs_to :model, optional: true, touch: true, counter_cache: true

  has_many :vehicles, dependent: :nullify
  has_many :item_prices, as: :item, dependent: :destroy

  has_one_attached :store_image
  has_one_attached :rsi_store_image
  has_one_attached :fleetchart_image
  has_one_attached :top_view
  has_one_attached :side_view
  has_one_attached :front_view
  has_one_attached :angled_view

  def self.ransackable_attributes(auth_object = nil)
    [
      "active", "created_at",
      "description",
      "hidden", "id", "id_value", "last_updated_at", "model_id", "name",
      "on_sale", "pledge_price", "production_note", "production_status", "rsi_description",
      "rsi_id", "rsi_name", "rsi_slug", "rsi_store_url",
      "slug", "store_images_updated_at",
      "store_url", "updated_at"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["model", "shop_commodities", "vehicles"]
  end

  DEFAULT_SORTING_PARAMS = "name asc"
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc", "createdAt asc", "createdAt desc", "updatedAt asc",
    "updatedAt desc", "model_slug asc", "model_slug desc"
  ]

  before_save :update_slugs

  def self.visible
    where(hidden: false)
  end

  def self.active
    where(active: true)
  end

  def sold_at
    item_prices.select(&:sell?).sort_by(&:price).uniq(&:location)
  end

  def bought_at
    item_prices.select(&:buy?).sort_by(&:price).uniq(&:location)
  end

  def name_with_model
    "#{model.name} - #{name}"
  end

  private def update_slugs
    super
    self.rsi_slug = generate_slug(rsi_name)
  end
end
