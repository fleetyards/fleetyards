# frozen_string_literal: true

# == Schema Information
#
# Table name: equipment
#
#  id                     :uuid             not null, primary key
#  backpack_compatibility :integer
#  core_compatibility     :integer
#  damage_reduction       :decimal(15, 2)
#  description            :text
#  equipment_type         :integer
#  extras                 :string
#  grade                  :string
#  hidden                 :boolean          default(TRUE)
#  item_type              :integer
#  name                   :string
#  range                  :decimal(15, 2)
#  rate_of_fire           :decimal(15, 2)
#  size                   :string
#  slot                   :integer
#  slug                   :string
#  storage                :decimal(15, 2)
#  store_image            :string
#  temperature_rating     :string
#  volume                 :decimal(15, 2)
#  weapon_class           :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  manufacturer_id        :uuid
#
# Indexes
#
#  index_equipment_on_manufacturer_id  (manufacturer_id)
#
class Equipment < ApplicationRecord
  paginates_per 50

  searchkick searchable: %i[name manufacturer_name manufacturer_code equipment_type item_type slot],
             word_start: %i[name manufacturer_name equipment_type item_type]

  def search_data
    {
      name: name,
      item_type: item_type,
      equipment_type: equipment_type,
      manufacturer_name: manufacturer&.name,
      manufacturer_code: manufacturer&.code,
      slot: slot
    }
  end

  def should_index?
    !hidden && (listed_at.present? || sold_at.present? || bought_at.present?)
  end

  belongs_to :manufacturer, optional: true
  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  validates :name, presence: true

  before_save :update_slugs
  after_save :touch_shop_commodities

  mount_uploader :store_image, ImageUploader

  ransack_alias :name, :name_or_slug

  enum equipment_type: { undersuit: 0, armor: 1, weapon: 2, tool: 3, clothing: 4, medical: 5, weapon_attachment: 6, hacking_tool: 7 }
  ransacker :equipment_type, formatter: proc { |v| Equipment.equipment_types[v] } do |parent|
    parent.table[:equipment_type]
  end

  enum slot: { undersuit: 0, arms: 1, helmet: 2, torso: 3, legs: 4, footwear: 5, hat: 6, gloves: 7, pants: 8, shirt: 9, jacket: 10, backpack: 11 }, _suffix: true
  ransacker :slot, formatter: proc { |v| Equipment.slots[v] } do |parent|
    parent.table[:slot]
  end

  enum item_type: {
    flightsuit: 0, light_armor: 1, medium_armor: 2, heavy_armor: 3, magazine: 4, battery: 5,
    pistol: 6, grenade: 7, smg: 8, rifle: 9, shotgun: 10, lmg: 11, sniper_rifle: 12,
    special_railgun: 13, assault_rifle: 14, weapon_scope: 15, utility: 16, rocket_launcher: 17,
    grenade_launcher: 18, knife: 19, backpack: 20, light_backpack: 21, medium_backpack: 22,
    heavy_backpack: 23
  }
  ransacker :item_type, formatter: proc { |v| Equipment.item_types[v] } do |parent|
    parent.table[:item_type]
  end

  enum weapon_class: { energy: 0, ballistic: 1, frag: 2 }
  ransacker :weapon_class, formatter: proc { |v| Equipment.weapon_classes[v] } do |parent|
    parent.table[:weapon_class]
  end

  enum core_compatibility: { all: 0, medium_heavy: 1, heavy: 2 }, _suffix: true
  enum backpack_compatibility: { all: 0, light_medium: 1, light: 2 }, _suffix: true

  def self.visible
    where(hidden: false)
  end

  def self.ordered_by_name
    visible.order(name: :asc)
  end

  def self.type_filters
    Equipment.equipment_types.map do |(item, _index)|
      Filter.new(
        category: 'equipment_type',
        name: Equipment.human_enum_name(:equipment_type, item),
        value: item
      )
    end
  end

  def self.item_type_filters
    Equipment.item_types.map do |(item, _index)|
      Filter.new(
        category: 'item_type',
        name: Equipment.human_enum_name(:item_type, item),
        value: item
      )
    end
  end

  def self.slot_filters
    Equipment.slots.map do |(item, _index)|
      Filter.new(
        category: 'slot',
        name: Equipment.human_enum_name(:slot, item),
        value: item
      )
    end
  end

  def sold_at
    shop_commodities.where.not(sell_price: nil).order(sell_price: :asc).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def bought_at
    shop_commodities.where.not(buy_price: nil).order(buy_price: :desc).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def listed_at
    shop_commodities.where(sell_price: nil, buy_price: nil).uniq { |item| "#{item.shop.station_id}-#{item.shop_id}" }
  end

  def equipment_type_label
    Equipment.human_enum_name(:equipment_type, equipment_type)
  end

  def item_type_label
    Equipment.human_enum_name(:item_type, item_type)
  end

  def slot_label
    Equipment.human_enum_name(:slot, slot)
  end

  def weapon_class_label
    Equipment.human_enum_name(:weapon_class, weapon_class)
  end

  def core_compatibility_label
    Equipment.human_enum_name(:core_compatibility, core_compatibility)
  end

  def backpack_compatibility_label
    Equipment.human_enum_name(:backpack_compatibility, backpack_compatibility)
  end

  private def touch_shop_commodities
    # rubocop:disable Rails/SkipsModelValidations
    shop_commodities.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
