# frozen_string_literal: true

class Equipment < ApplicationRecord
  paginates_per 50

  belongs_to :manufacturer, optional: true
  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  validates :name, presence: true

  before_save :update_slugs
  after_save :touch_shop_commodities

  mount_uploader :store_image, StoreImageUploader

  ransack_alias :name, :name_or_slug

  enum equipment_type: { undersuit: 0, armor: 1, weapon: 2, tool: 3, clothing: 4, medical: 5, weapon_attachment: 6, hacking_tool: 7 }
  ransacker :equipment_type, formatter: proc { |v| Equipment.equipment_types[v] } do |parent|
    parent.table[:equipment_type]
  end

  enum slot: { undersuit: 0, arms: 1, helmet: 2, torso: 3, legs: 4, footwear: 5, hat: 6, gloves: 7, pants: 8, shirt: 9, jacket: 10 }, _suffix: true
  ransacker :slot, formatter: proc { |v| Equipment.slots[v] } do |parent|
    parent.table[:slot]
  end

  enum item_type: { flightsuit: 0, light_armor: 1, medium_armor: 2, heavy_armor: 3, magazine: 4, battery: 5, pistol: 6, grenade: 7, smg: 8, rifle: 9, shotgun: 10, lmg: 11, sniper_rifle: 12, special_railgun: 13, assault_rifle: 14, weapon_scope: 15, utility: 16, rocket_launcher: 17, grenade_launcher: 18, knife: 19, }
  ransacker :item_type, formatter: proc { |v| Equipment.item_types[v] } do |parent|
    parent.table[:item_type]
  end

  enum weapon_class: { energy: 0, ballistic: 1, frag: 2 }
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
