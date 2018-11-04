# frozen_string_literal: true

class Equipment < ApplicationRecord
  include SlugHelper

  belongs_to :manufacturer, required: false

  validates :name, presence: true

  before_save :update_slugs

  mount_uploader :store_image, StoreImageUploader

  enum equipment_type: %i[undersuit armor weapon tool clothing medical weapon_attachment]
  ransacker :equipment_type, formatter: proc { |v| Equipment.equipment_types[v] } do |parent|
    parent.table[:equipment_type]
  end

  enum slot: %i[undersuit arms helmet torso legs], _suffix: true
  ransacker :slot, formatter: proc { |v| Equipment.slots[v] } do |parent|
    parent.table[:slot]
  end

  enum item_type: %i[
    flightsuit light_armor medium_armor heavy_armor magazine pistol grenade smg rifle
    shotgun lmg sniper_rifle special_railgun
  ]
  ransacker :item_type, formatter: proc { |v| Equipment.item_types[v] } do |parent|
    parent.table[:item_type]
  end

  enum weapon_class: %i[energy balistic]
  ransacker :weapon_class, formatter: proc { |v| Equipment.weapon_classes[v] } do |parent|
    parent.table[:weapon_class]
  end

  def self.ordered_by_name
    order(name: :asc)
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

  private def update_slugs
    self.slug = SlugHelper.generate_slug(name)
  end
end
