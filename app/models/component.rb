# frozen_string_literal: true

class Component < ApplicationRecord
  paginates_per 50

  belongs_to :manufacturer, optional: true
  has_many :shop_commodities, as: :commodity_item, dependent: :destroy

  validates :name, presence: true

  before_save :update_slugs
  after_save :touch_shop_commodities

  mount_uploader :store_image, StoreImageUploader

  def self.ordered_by_name
    order(name: :asc)
  end

  enum item_class: { stealth: 0, civilian: 1, industrial: 2, military: 3, competition: 4 }
  ransacker :item_class, formatter: proc { |v| Component.item_classes[v] } do |parent|
    parent.table[:item_class]
  end

  ransack_alias :name, :name_or_slug

  def self.item_types
    %w[
      weapons
      turrets
      shield_generators
      missiles
      coolers
      power_plants
      quantum_drives
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

  def self.class_filters
    Component.all.map(&:component_class).uniq.compact.map do |item|
      Filter.new(
        category: 'class',
        name: I18n.t("filter.component.class.items.#{item.downcase}"),
        value: item
      )
    end
  end

  def item_class_label
    Component.human_enum_name(:item_class, item_class)
  end

  def item_type_label
    Component.human_enum_name(:item_type, item_type)
  end

  def component_class_label
    I18n.t("filter.component.class.items.#{component_class.downcase}")
  end

  private def touch_shop_commodities
    # rubocop:disable Rails/SkipsModelValidations
    shop_commodities.update_all(updated_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
