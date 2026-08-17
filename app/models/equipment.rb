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
#  equipment_type         :string
#  g_force_tolerance      :decimal(15, 2)
#  grade                  :string
#  hidden                 :boolean          default(FALSE)
#  item_type              :string
#  name                   :string
#  radiation_protection   :decimal(15, 2)
#  radiation_scrub_rate   :decimal(15, 2)
#  range                  :decimal(15, 2)
#  rate_of_fire           :decimal(15, 2)
#  sc_key                 :string
#  sc_ref                 :string
#  size                   :string
#  slot                   :integer
#  slug                   :string
#  storage                :decimal(15, 2)
#  sub_type               :string
#  temperature_rating     :string
#  version                :string
#  volume                 :decimal(15, 2)
#  weapon_class           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  manufacturer_id        :uuid
#
# Indexes
#
#  index_equipment_on_equipment_type   (equipment_type)
#  index_equipment_on_item_type        (item_type)
#  index_equipment_on_manufacturer_id  (manufacturer_id)
#  index_equipment_on_sc_key           (sc_key) UNIQUE
#  index_equipment_on_slot             (slot)
#
class Equipment < ApplicationRecord
  paginates_per 50

  belongs_to :manufacturer, optional: true

  # Nothing fills this from the game files: the loadout icons the records name
  # are art the export leaves out on purpose. It is here for the same reason
  # every other catalogue has one -- an upload, and the ledger's fallback to
  # the referenced item's picture.
  has_one_attached :store_image
  has_many :item_prices, as: :item, dependent: :destroy

  validates :name, presence: true
  validates :sc_key, uniqueness: true, allow_nil: true

  before_save :update_slugs

  ransack_alias :name, :name_or_slug

  # The game's own split, from AttachDef Type. Armour and clothing join these
  # when the character trees land; they are the same kind of thing worn or
  # carried by a player, and share this table.
  EQUIPMENT_TYPES = %w[
    weapon weapon_attachment tool armor clothing undersuit medical hacking_tool
  ].freeze

  # Kept as free strings rather than an enum: CIG adds weapon classes between
  # builds, and a new one should load rather than raise. Same reasoning as
  # Commodity#commodity_type.
  WEAPON_CLASSES = %w[ballistic energy kinetic frag].freeze

  DEFAULT_SORTING_PARAMS = ["name asc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "itemType asc", "itemType desc",
    "createdAt asc", "createdAt desc",
    "updatedAt asc", "updatedAt desc"
  ]

  enum :slot,
    {
      undersuit: 0, arms: 1, helmet: 2, torso: 3, legs: 4, footwear: 5, hat: 6, gloves: 7,
      pants: 8, shirt: 9, jacket: 10, backpack: 11
    },
    suffix: true
  ransacker :slot, formatter: proc { |v| Equipment.slots[v] } do |parent|
    parent.table[:slot]
  end

  enum :core_compatibility,
    {all: 0, medium_heavy: 1, heavy: 2},
    suffix: true

  enum :backpack_compatibility,
    {all: 0, light_medium: 1, light: 2},
    suffix: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id name slug sc_key equipment_type item_type sub_type weapon_class size grade
      hidden manufacturer_id range rate_of_fire storage created_at updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    ["manufacturer"]
  end

  # Gear from past patches stays in the table -- a ledger entry made last patch
  # still has to resolve its item -- so anything meant for a picker narrows to
  # the version the game currently ships. Component keeps the same scope.
  scope :current_version, ->(flag = true) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(version: Rails.configuration.sc_data[:version])
    else
      all
    end
  }

  def self.visible
    where(hidden: false)
  end

  def self.ordered_by_name
    visible.order(name: :asc)
  end

  def self.equipment_types
    visible.current_version.where.not(equipment_type: nil).distinct.order(:equipment_type).pluck(:equipment_type)
  end

  def self.type_filters
    equipment_types.map do |item|
      Filter.new(
        category: "equipment_type",
        label: I18n.t("filter.equipment.equipment_type.items.#{item}", default: item.humanize),
        value: item
      )
    end
  end

  def self.slot_filters
    slots.map do |(item, _index)|
      Filter.new(
        category: "slot",
        label: human_enum_name(:slot, item),
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

  def self.item_types
    visible.current_version.where.not(item_type: nil).distinct.order(:item_type).pluck(:item_type)
  end

  def self.item_type_filters
    item_types.map do |item|
      Filter.new(
        category: "item_type",
        label: I18n.t("filter.equipment.item_type.items.#{item}", default: item.humanize),
        value: item
      )
    end
  end
end
