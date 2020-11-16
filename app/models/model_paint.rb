# frozen_string_literal: true

# == Schema Information
#
# Table name: model_paints
#
#  id                      :uuid             not null, primary key
#  active                  :boolean          default(TRUE)
#  description             :string
#  fleetchart_image        :string
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
#  slug                    :string
#  starship42_slug         :string
#  store_image             :string
#  store_images_updated_at :datetime
#  store_url               :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_id                :uuid
#  rsi_id                  :integer
#
class ModelPaint < ApplicationRecord
  paginates_per 30

  belongs_to :model, optional: true, touch: true, counter_cache: true

  has_many :vehicles, dependent: :nullify
  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

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

  def sold_at
    shop_commodities.where.not(sell_price: nil).uniq { |item| item.shop.slug }
  end

  def bought_at
    shop_commodities.where.not(buy_price: nil).uniq { |item| item.shop.slug }
  end

  def name_with_model
    "#{model.name} - #{name}"
  end

  private def update_slugs
    super
    self.rsi_slug = SlugHelper.generate_slug(rsi_name)
  end
end
