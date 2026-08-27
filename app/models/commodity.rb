# frozen_string_literal: true

# == Schema Information
#
# Table name: commodities
#
#  id             :uuid             not null, primary key
#  commodity_type :string
#  description    :text
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
  include AttachmentRansackers
  include ItemPriceConcern
  include ScDataVersioned

  paginates_per 60

  has_many :fleet_inventory_items, as: :item, dependent: :nullify
  has_many :inventory_items, as: :item, dependent: :nullify

  # What each build of the game says about this commodity. Written alongside the
  # columns, and read through in preference to them.
  has_many :builds, class_name: "CommodityBuild", dependent: :destroy
  has_one :build, -> { current }, class_name: "CommodityBuild", inverse_of: :commodity

  # The newest build of this environment that still describes the commodity,
  # which is what a record the export dropped falls back to. Without it a retired
  # commodity would read as nameless, and an inventory item pointing at one has
  # to resolve to something.
  has_one :last_build,
    -> { for_source.order(created_at: :desc) },
    class_name: "CommodityBuild", inverse_of: :commodity

  # Named as every other catalogue names its picture, so a ledger entry
  # pointing at a commodity draws it through the same fallback that already
  # gives a component its artwork.
  has_one_attached :store_image
  ransack_attachment :store_image

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
    %w[id name slug commodity_type sc_key uex_code store_image created_at updated_at] +
      ItemPriceConcern::RANSACKABLE_ATTRIBUTES
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
