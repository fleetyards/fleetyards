# frozen_string_literal: true

class Equipment < ApplicationRecord
  paginates_per 50

  belongs_to :manufacturer, optional: true
  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  validates :name, presence: true

  before_save :update_slugs
  after_save :touch_shop_commodities

  mount_uploader :store_image, StoreImageUploader

  enum equipment_type: %i[undersuit armor weapon tool clothing medical weapon_attachment]
  ransacker :equipment_type, formatter: proc { |v| Equipment.equipment_types[v] } do |parent|
    parent.table[:equipment_type]
  end

  enum slot: %i[undersuit arms helmet torso legs footwear hat gloves pants shirt jacket], _suffix: true
  ransacker :slot, formatter: proc { |v| Equipment.slots[v] } do |parent|
    parent.table[:slot]
  end

  enum item_type: %i[
    flightsuit light_armor medium_armor heavy_armor magazine battery pistol grenade smg rifle
    shotgun lmg sniper_rifle special_railgun assault_rifle weapon_scope
  ]
  ransacker :item_type, formatter: proc { |v| Equipment.item_types[v] } do |parent|
    parent.table[:item_type]
  end

  enum weapon_class: %i[energy ballistic]
  ransacker :weapon_class, formatter: proc { |v| Equipment.weapon_classes[v] } do |parent|
    parent.table[:weapon_class]
  end

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

  private def touch_shop_commodities
    # rubocop:disable Rails/SkipsModelValidations
    shop_commodities.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
