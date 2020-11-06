# frozen_string_literal: true

# == Schema Information
#
# Table name: shop_commodities
#
#  id                           :uuid             not null, primary key
#  average_buy_price            :decimal(15, 2)
#  average_rental_price_1_day   :decimal(15, 2)
#  average_rental_price_30_days :decimal(15, 2)
#  average_rental_price_3_days  :decimal(15, 2)
#  average_rental_price_7_days  :decimal(15, 2)
#  average_sell_price           :decimal(15, 2)
#  buy_price                    :decimal(15, 2)
#  commodity_item_type          :string
#  confirmed                    :boolean          default(FALSE)
#  price_per_unit               :boolean          default(FALSE)
#  rental_price_1_day           :decimal(15, 2)
#  rental_price_30_days         :decimal(15, 2)
#  rental_price_3_days          :decimal(15, 2)
#  rental_price_7_days          :decimal(15, 2)
#  sell_price                   :decimal(15, 2)
#  submitted_by                 :uuid
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  commodity_item_id            :uuid
#  shop_id                      :uuid
#
# Indexes
#
#  index_shop_commodities_on_commodity_item_id      (commodity_item_id)
#  index_shop_commodities_on_item_type_and_item_id  (commodity_item_type,commodity_item_id)
#  index_shop_commodities_on_shop_id                (shop_id)
#
class ShopCommodity < ApplicationRecord
  paginates_per 30

  searchkick searchable: %i[name manufacturer_name manufacturer_code shop station celestial_object starsystem],
             word_start: %i[name manufacturer_name],
             filterable: []

  def search_data
    {
      name: commodity_item.name,
      manufacturer_name: commodity_item.manufacturer&.name,
      manufacturer_code: commodity_item.manufacturer&.code,
      shop: shop.name,
      station: shop.station.name,
      celestial_object: shop.station.celestial_object.name,
      starsystem: shop.station.celestial_object.starsystem&.name
    }
  end

  def should_index?
    commodity_item.is_a?(Equipment) || commodity_item.is_a?(Component)
  end

  belongs_to :commodity_item, polymorphic: true, optional: true
  belongs_to :model,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'Model' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  belongs_to :component,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'Component' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  belongs_to :commodity,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'Commodity' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  belongs_to :equipment,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'Equipment' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  belongs_to :model_module,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'ModelModule' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  belongs_to :model_paint,
             -> { includes(:shop_commodities).where(shop_commodities: { commodity_item_type: 'ModelPaint' }) },
             foreign_key: 'commodity_item_id',
             inverse_of: :shop_commodities,
             required: false

  has_many :commodity_sell_prices, dependent: :destroy
  has_many :commodity_buy_prices, dependent: :destroy
  has_many :commodity_rental_prices, dependent: :destroy

  has_many :trade_route_origins,
           class_name: 'TradeRoute',
           dependent: :destroy,
           foreign_key: 'origin_id',
           inverse_of: :origin

  has_many :trade_route_destinations,
           class_name: 'TradeRoute',
           dependent: :destroy,
           foreign_key: 'destination_id',
           inverse_of: :destination

  belongs_to :shop

  validates :commodity_item, presence: true

  before_validation :set_commodity_item
  after_save :update_model_price

  attr_accessor :commodity_item_selected

  ransack_alias :name, :model_name_or_component_name_or_commodity_name_or_equipment_name_or_model_module_name
  ransack_alias :category, :commodity_item_type
  ransack_alias :sub_category, :model_classification_or_component_component_class_or_equipment_equipment_type
  ransack_alias :manufacturer, :model_manufacturer_slug_or_component_manufacturer_slug_or_equipment_manufacturer_slug_or_model_module_manufacturer_slug
  ransack_alias :price, :sell_price_or_buy_price_or_rent_price

  def self.commodity_item_types
    %w[Model Equipment Commodity Component ModelModule ModelPaint]
  end

  def self.commodity
    where(commodity_item_type: ['Commodity'])
  end

  def self.visible
    includes(:shop).where(shops: { hidden: false })
  end

  def set_commodity_item
    return if commodity_item_selected.blank?

    self.commodity_item = GlobalID::Locator.locate(commodity_item_selected)
  end

  def update_prices
    update_buy_prices
    update_sell_prices
    update_rental_prices
  end

  def update_buy_prices
    buy_prices = commodity_buy_prices
      .where(created_at: (Time.zone.today - 1.month)..)
      .order(created_at: :desc).pluck(:price)

    if buy_prices.present?
      update(
        buy_price: buy_prices.first,
        average_buy_price: buy_prices.sum / buy_prices.size
      )
    else
      update(
        buy_price: nil,
        average_buy_price: nil
      )
    end
  end

  def update_sell_prices
    sell_prices = commodity_sell_prices
      .where(created_at: (Time.zone.today - 1.month)..)
      .order(created_at: :desc).pluck(:price)

    if sell_prices.present?
      update(
        sell_price: sell_prices.first,
        average_sell_price: sell_prices.sum / sell_prices.size
      )
    else
      update(
        sell_price: nil,
        average_sell_price: nil
      )
    end
  end

  def update_rental_prices
    update_1_day_prices
    update_3_days_prices
    update_7_days_prices
    update_30_days_prices
  end

  def update_1_day_prices
    rental_prices_1_day = commodity_rental_prices
      .where(
        created_at: (Time.zone.today - 1.month)..,
        time_range: '1-day'
      )
      .order(created_at: :desc)
      .pluck(:price)

    if rental_prices_1_day.present?
      update(
        rental_price_1_day: rental_prices_1_day.first,
        average_rental_price_1_day: (rental_prices_1_day.sum / rental_prices_1_day.size)
      )
    else
      update(
        rental_price_1_day: nil,
        average_rental_price_1_day: nil
      )
    end
  end

  def update_3_days_prices
    rental_prices_3_days = commodity_rental_prices
      .where(
        created_at: (Time.zone.today - 1.month)..,
        time_range: '3-days'
      )
      .order(created_at: :desc)
      .pluck(:price)

    if rental_prices_3_days.present?
      update(
        rental_price_3_days: rental_prices_3_days.first,
        average_rental_price_3_days: (rental_prices_3_days.sum / rental_prices_3_days.size)
      )
    else
      update(
        rental_price_3_days: nil,
        average_rental_price_3_days: nil
      )
    end
  end

  def update_7_days_prices
    rental_prices_7_days = commodity_rental_prices
      .where(
        created_at: (Time.zone.today - 1.month)..,
        time_range: '7-days'
      )
      .order(created_at: :desc)
      .pluck(:price)

    if rental_prices_7_days.present?
      update(
        rental_price_7_days: rental_prices_7_days.first,
        average_rental_price_7_days: (rental_prices_7_days.sum / rental_prices_7_days.size)
      )
    else
      update(
        rental_price_7_days: nil,
        average_rental_price_7_days: nil
      )
    end
  end

  def update_30_days_prices
    rental_prices_30_days = commodity_rental_prices
      .where(
        created_at: (Time.zone.today - 1.month)..,
        time_range: '30-days'
      )
      .order(created_at: :desc)
      .pluck(:price)

    if rental_prices_30_days.present?
      update(
        rental_price_30_days: rental_prices_30_days.first,
        average_rental_price_30_days: (rental_prices_30_days.sum / rental_prices_30_days.size)
      )
    else
      update(
        rental_price_30_days: nil,
        average_rental_price_30_days: nil
      )
    end
  end

  def update_model_price
    return if model.blank?

    model.update(price: CommoditySellPrice.where(shop_commodity_id: model.shop_commodity_ids).order(price: :asc).first&.price)
  end

  def category
    commodity_item.class.name.underscore
  end

  def sub_category
    case commodity_item_type
    when 'Model'
      commodity_item.classification
    when 'Component'
      commodity_item.component_class
    when 'Equipment'
      commodity_item.equipment_type
    when 'Commodity'
      commodity_item.commodity_type
    end
  end

  def sub_category_label
    case commodity_item_type
    when 'Model'
      commodity_item.classification&.humanize
    when 'Component'
      commodity_item.component_class_label
    when 'Equipment'
      commodity_item.equipment_type_label
    when 'Commodity'
      commodity_item.commodity_type_label
    end
  end

  def location_label
    [
      I18n.t('activerecord.attributes.shop_commodity.location_prefix.default'),
      shop.name,
      I18n.t('activerecord.attributes.station.location_prefix.default'),
      shop.station.name
    ].join(' ')
  end
end
