# frozen_string_literal: true

# == Schema Information
#
# Table name: components
#
#  id                    :uuid             not null, primary key
#  ammunition            :string
#  category              :string
#  component_class       :string
#  component_sub_type    :string
#  component_type        :string
#  description           :text
#  durability            :string
#  grade                 :string
#  heat_connection       :string
#  hidden                :boolean          default(FALSE)
#  inventory_consumption :string
#  item_class            :integer
#  item_type             :string
#  name                  :string(255)
#  power_connection      :string
#  sc_key                :string
#  sc_ref                :string
#  size                  :string(255)
#  slug                  :string
#  tracking_signal       :integer
#  type_data             :string
#  version               :string
#  created_at            :datetime
#  updated_at            :datetime
#  manufacturer_id       :uuid
#
# Indexes
#
#  index_components_on_manufacturer_id  (manufacturer_id)
#  index_components_on_sc_key           (sc_key) UNIQUE
#  index_components_on_version          (version)
#
class Component < ApplicationRecord
  include ActiveStorageVariants
  include ItemPriceConcern

  paginates_per 50
  max_paginates_per 240

  # One row per component, with the spec history kept as versions rather than as
  # a row per build. `version` is deliberately not tracked: it moves on every
  # import, and recording that would write a version per component per run for
  # nothing. Only a spec that actually changed is worth keeping.
  #
  # The associations are renamed because PaperTrail's default `version` reader
  # shadows this table's `version` column -- left alone, an update writes NULL
  # over the build a component was last seen in.
  has_paper_trail on: %i[update],
    only: %i[
      name description size grade item_type item_class component_class component_sub_type
      component_type type_data durability power_connection heat_connection ammunition
      inventory_consumption tracking_signal manufacturer_id hidden
    ],
    version: :paper_trail_version,
    versions: {name: :paper_trail_versions}

  belongs_to :manufacturer, optional: true

  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true
  has_many :hardpoint_loadouts, class_name: "Hardpoint", dependent: :nullify

  has_many :model_hardpoints, dependent: :nullify

  before_save :update_slugs
  before_save :extract_data_from_description

  has_one_attached :store_image

  serialize :type_data, coder: YAML
  serialize :durability, coder: YAML
  serialize :power_connection, coder: YAML
  serialize :heat_connection, coder: YAML
  serialize :ammunition, coder: YAML
  serialize :inventory_consumption, coder: YAML

  # Components of past patches stay in the table, so anything meant for a
  # picker has to narrow down to the version the game currently ships.
  scope :current_version, ->(flag = true) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(version: Rails.configuration.sc_data[:version])
    else
      all
    end
  }

  DEFAULT_SORTING_PARAMS = ["name asc", "created_at asc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc", "createdAt asc", "createdAt desc"
  ]

  def self.ordered_by_name
    order(name: :asc)
  end

  enum :item_class,
    {stealth: 0, civilian: 1, industrial: 2, military: 3, competition: 4}
  ransacker :item_class, formatter: proc { |v| Component.item_classes[v] } do |parent|
    parent.table[:item_class]
  end

  enum :tracking_signal,
    {infrared: 0, cross_section: 1, electromagnetic: 2}
  ransacker :tracking_signal, formatter: proc { |v| Component.tracking_signals[v] } do |parent|
    parent.table[:tracking_signal]
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "ammunition", "category", "component_class", "component_sub_type", "component_type",
      "created_at", "description", "durability", "grade",
      "heat_connection", "hidden", "id", "id_value", "item_class", "item_type", "manufacturer_id", "name",
      "power_connection", "size", "slug", "tracking_signal",
      "type_data", "updated_at", "version"
    ] + ItemPriceConcern::RANSACKABLE_ATTRIBUTES
  end

  def self.ransackable_associations(auth_object = nil)
    ["manufacturer", "shop_commodities"]
  end

  def self.ransackable_scopes(auth_object = nil)
    ["current_version"]
  end

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
      manned_utility_turrets
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
      emps
      armor_medium
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

  def self.categories
    current_version.distinct.pluck(:category).compact_blank.sort
  end

  def self.sub_types(category: nil)
    scope = current_version
    scope = scope.where(category: category) if category.present?

    scope.distinct.pluck(:component_sub_type).compact_blank.sort
  end

  def self.item_type_filters
    Component.item_types.map do |item|
      Filter.new(
        category: "item_type",
        label: I18n.t("activerecord.attributes.component.item_types.#{item.downcase}"),
        value: item
      )
    end
  end

  # Categories and sub types come straight out of the game files, so a patch can
  # introduce values we have no label for yet — fall back to the raw value
  # instead of rendering a translation-missing string into the API.
  def self.category_filters
    Component.categories.map do |item|
      Filter.new(
        category: "category",
        label: I18n.t("filter.component.category.items.#{item}", default: item.titleize),
        value: item
      )
    end
  end

  def self.sub_type_filters(category: nil)
    Component.sub_types(category: category).map do |item|
      Filter.new(
        category: "sub_type",
        label: I18n.t("filter.component.sub_type.items.#{item.underscore}", default: item.underscore.titleize),
        value: item
      )
    end
  end

  def self.class_filters
    Component.all.map(&:component_class).uniq.compact.map do |item|
      Filter.new(
        category: "class",
        label: I18n.t("filter.component.class.items.#{item.downcase}"),
        value: item
      )
    end
  end

  def extract_data_from_description
    return if description.blank?

    cleaned_description, data = description.gsub("\\n", "\n").split("\n\n", 2).reverse

    self.description = cleaned_description.delete("\n").gsub(/[[:space:]]+/, "").chomp

    return if data.blank?

    data.split("\n").each do |line|
      key, value = line.split(":", 2)

      case key.strip
      when "Class"
        self.item_class = value.gsub(/[[:space:]]+/, "").downcase
      end
    end
  end

  def grade_label
    return if grade.blank?
    return if grade.to_i > 4 || grade.to_i < 1

    grade.to_s.tr("1234", "ABCD")
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
end
