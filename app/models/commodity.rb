# frozen_string_literal: true

# == Schema Information
#
# Table name: commodities
#
#  id             :uuid             not null, primary key
#  commodity_type :string
#  description    :text
#  icon           :string
#  name           :string           not null
#  sc_key         :string
#  sc_ref         :string
#  slug           :string           not null
#  uex_code       :string
#  version        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  uex_id         :integer
#
# Indexes
#
#  index_commodities_on_commodity_type  (commodity_type)
#  index_commodities_on_sc_key          (sc_key) UNIQUE
#  index_commodities_on_slug            (slug) UNIQUE
#  index_commodities_on_uex_code        (uex_code)
#
class Commodity < ApplicationRecord
  paginates_per 60

  has_many :fleet_inventory_items, as: :item, dependent: :nullify
  has_many :inventory_items, as: :item, dependent: :nullify

  before_save :update_slugs

  validates :sc_key, uniqueness: true, allow_nil: true
  validates :name, presence: true

  # Mirrors the displayType keys the game files ship. Stored as a string rather
  # than an enum so a type added in a future build loads instead of raising.
  TYPES = %w[
    agricultural_supply alloy consumer_goods drink food gas hpmc manmade
    medical_supply metal military_supply mineral natural nonmetals plasma_fuel
    processed_goods quantum_fuel rmc scrap vice waste
  ].freeze

  # Commodities of past patches stay in the table -- a ledger entry made last
  # patch still has to resolve its item -- so anything meant for a picker
  # narrows to the version the game currently ships. Component and Equipment
  # keep the same scope.
  scope :current_version, ->(flag = true) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(version: Rails.configuration.sc_data[:version])
    else
      all
    end
  }

  DEFAULT_SORTING_PARAMS = ["name asc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "commodityType asc", "commodityType desc",
    "createdAt asc", "createdAt desc",
    "updatedAt asc", "updatedAt desc"
  ]

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name slug commodity_type sc_key uex_code created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.commodity_types
    current_version.where.not(commodity_type: nil).distinct.order(:commodity_type).pluck(:commodity_type)
  end

  def self.type_filters
    commodity_types.map do |item|
      Filter.new(
        category: "commodity_type",
        label: I18n.t("filter.commodity.commodity_type.items.#{item}", default: item.titleize),
        value: item
      )
    end
  end
end
