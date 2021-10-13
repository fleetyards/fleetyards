# frozen_string_literal: true

# == Schema Information
#
# Table name: components
#
#  id               :uuid             not null, primary key
#  ammunition       :string
#  component_class  :string
#  description      :text
#  durability       :string
#  grade            :string
#  heat_connection  :string
#  item_class       :integer
#  item_type        :string
#  name             :string(255)
#  power_connection :string
#  sc_identifier    :string
#  size             :string(255)
#  slug             :string
#  store_image      :string
#  tracking_signal  :integer
#  type_data        :string
#  created_at       :datetime
#  updated_at       :datetime
#  manufacturer_id  :uuid
#
# Indexes
#
#  index_components_on_manufacturer_id  (manufacturer_id)
#
class Component < ApplicationRecord
  paginates_per 50

  searchkick searchable: %i[name manufacturer_name manufacturer_code item_type item_class],
             word_start: %i[name manufacturer_name item_type],
             filterable: []

  def search_data
    {
      name: name,
      item_type: (item_type || '').tr('_', ' '),
      item_class: item_class,
      manufacturer_name: manufacturer&.name,
      manufacturer_code: manufacturer&.code
    }
  end

  def should_index?
    listed_at.present?
  end

  belongs_to :manufacturer, optional: true
  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  validates :name, presence: true

  before_save :update_slugs
  after_save :touch_shop_commodities

  mount_uploader :store_image, StoreImageUploader

  serialize :type_data
  serialize :durability
  serialize :power_connection
  serialize :heat_connection
  serialize :ammunition

  def self.ordered_by_name
    order(name: :asc)
  end

  enum item_class: { stealth: 0, civilian: 1, industrial: 2, military: 3, competition: 4 }
  ransacker :item_class, formatter: proc { |v| Component.item_classes[v] } do |parent|
    parent.table[:item_class]
  end

  enum tracking_signal: { infrared: 0, cross_section: 1, electromagnetic: 2 }
  ransacker :tracking_signal, formatter: proc { |v| Component.tracking_signals[v] } do |parent|
    parent.table[:tracking_signal]
  end

  ransack_alias :name, :name_or_slug

  def self.item_types
    %w[
      shield_generators
      coolers
      power_plants
      quantum_drives
      weapons
      turrets
      manned_turrets
      remote_turrets
      missile_turrets
      missiles
      missile_racks
      mining_lasers
      fuel_intakes
      fuel_tanks
      quantum_fuel_tanks
      scanners
      mid_range_radar
      thrusters
      joint_thrusters
      fixed_thrusters
      weapon_defensive
      countermeasure_launcher
      cargo_grids
    ]
  end

  def self.component_classes
    %w[
      RSIModular
      RSIWeapon
      RSIAvionic
      RSIPropulsion
      RSIThruster
    ]
  end

  def self.item_type_filters
    Component.item_types.map do |item|
      Filter.new(
        category: 'item_type',
        name: I18n.t("activerecord.attributes.component.item_types.#{item.downcase}"),
        value: item
      )
    end
  end

  def self.class_filters
    Component.all.map(&:component_class).uniq.compact.map do |item|
      Filter.new(
        category: 'class',
        name: I18n.t("filter.component.class.items.#{item.downcase}"),
        value: item
      )
    end
  end

  def listed_at
    shop_commodities.where(sell_price: nil, buy_price: nil).uniq { |item| item.shop.slug }
  end

  def sold_at
    shop_commodities.where.not(sell_price: nil).uniq { |item| item.shop.slug }
  end

  def bought_at
    shop_commodities.where.not(buy_price: nil).uniq { |item| item.shop.slug }
  end

  def item_class_label
    Component.human_enum_name(:item_class, item_class)
  end

  def item_type_label
    Component.human_enum_name(:item_type, item_type)
  end

  def component_class_label
    I18n.t("filter.component.class.items.#{component_class.downcase}") if component_class.present?
  end

  def tracking_signal_label
    Component.human_enum_name(:tracking_signal, tracking_signal)
  end

  private def touch_shop_commodities
    # rubocop:disable Rails/SkipsModelValidations
    shop_commodities.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
