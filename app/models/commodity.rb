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
#  uex_slug       :string
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
#  index_commodities_on_uex_slug        (uex_slug)
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

  DEFAULT_SORTING_PARAMS = ["name asc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "commodityType asc", "commodityType desc",
    "createdAt asc", "createdAt desc",
    "updatedAt asc", "updatedAt desc"
  ]

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug commodity_type sc_key uex_slug created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
