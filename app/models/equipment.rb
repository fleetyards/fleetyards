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
#  store_image_height     :integer
#  store_image_width      :integer
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
      name:,
      item_type:,
      equipment_type:,
      manufacturer_name: manufacturer&.name,
      manufacturer_code: manufacturer&.code,
      slot:
    }
  end

  def should_index?
    !hidden && (sold_at.present? || bought_at.present?)
  end

  belongs_to :manufacturer, optional: true
  has_many :item_prices, as: :item, dependent: :destroy

  validates :name, presence: true

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  ransack_alias :name, :name_or_slug

  def self.ransackable_attributes(auth_object = nil)
    [
      "backpack_compatibility", "core_compatibility", "created_at", "damage_reduction",
      "description", "equipment_type", "extras", "grade", "hidden", "id", "id_value", "item_type",
      "manufacturer_id", "name", "range", "rate_of_fire", "size", "slot", "slug", "storage",
      "store_image", "temperature_rating", "updated_at", "volume", "weapon_class"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["manufacturer", "shop_commodities"]
  end

  enum :equipment_type,
    {
      undersuit: 0, armor: 1, weapon: 2, tool: 3, clothing: 4, medical: 5,
      weapon_attachment: 6, hacking_tool: 7
    }
  ransacker :equipment_type, formatter: proc { |v| Equipment.equipment_types[v] } do |parent|
    parent.table[:equipment_type]
  end

  enum :slot,
    {
      undersuit: 0, arms: 1, helmet: 2, torso: 3, legs: 4, footwear: 5, hat: 6, gloves: 7,
      pants: 8, shirt: 9, jacket: 10, backpack: 11
    },
    suffix: true
  ransacker :slot, formatter: proc { |v| Equipment.slots[v] } do |parent|
    parent.table[:slot]
  end

  enum :item_type,
    {
      flightsuit: 0, light_armor: 1, medium_armor: 2, heavy_armor: 3, magazine: 4, battery: 5,
      pistol: 6, grenade: 7, smg: 8, rifle: 9, shotgun: 10, lmg: 11, sniper_rifle: 12,
      special_railgun: 13, assault_rifle: 14, weapon_scope: 15, utility: 16, rocket_launcher: 17,
      grenade_launcher: 18, knife: 19, backpack: 20, light_backpack: 21, medium_backpack: 22,
      heavy_backpack: 23
    }
  ransacker :item_type, formatter: proc { |v| Equipment.item_types[v] } do |parent|
    parent.table[:item_type]
  end

  enum :weapon_class,
    {energy: 0, ballistic: 1, frag: 2}
  ransacker :weapon_class, formatter: proc { |v| Equipment.weapon_classes[v] } do |parent|
    parent.table[:weapon_class]
  end

  enum :core_compatibility,
    {all: 0, medium_heavy: 1, heavy: 2},
    suffix: true

  enum :backpack_compatibility,
    {all: 0, light_medium: 1, light: 2},
    suffix: true

  def self.visible
    where(hidden: false)
  end

  def self.ordered_by_name
    visible.order(name: :asc)
  end

  def self.type_filters
    Equipment.equipment_types.map do |(item, _index)|
      Filter.new(
        category: "equipment_type",
        label: Equipment.human_enum_name(:equipment_type, item),
        value: item
      )
    end
  end

  def self.item_type_filters
    Equipment.item_types.map do |(item, _index)|
      Filter.new(
        category: "item_type",
        label: Equipment.human_enum_name(:item_type, item),
        value: item
      )
    end
  end

  def self.slot_filters
    Equipment.slots.map do |(item, _index)|
      Filter.new(
        category: "slot",
        label: Equipment.human_enum_name(:slot, item),
        value: item
      )
    end
  end

  def sold_at
    item_prices.sell.order(price: :asc).uniq(&:location)
  end

  def bought_at
    item_prices.buy.order(price: :asc).uniq(&:location)
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
end
