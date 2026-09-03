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
  attr_accessor :update_reason, :update_reason_description, :author_id

  # Only an admin action sets `author_id`, so a loader write files nothing. The
  # gate is not tidiness: the UEX sync rewrites all 232 commodities and 1,526 of
  # 4,830 equipment rows a week, and versioning those unconditionally would bury
  # the handful of real edits the way Fleet's touch versions already do.
  has_paper_trail on: %i[update],
    only: %i[
      name description commodity_type uex_id uex_code sc_key sc_ref
    ],
    if: ->(record) { record.author_id.present? },
    # `version` here is the sc_data build the row was last loaded from, and
    # paper_trail claims that name for its own accessor unless told otherwise.
    # Component already carries this rename for the same reason.
    version: :paper_trail_version,
    versions: {name: :paper_trail_versions},
    meta: {
      author_id: :author_id,
      reason: :update_reason,
      reason_description: :update_reason_description
    }
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

  # Whether the build we are on describes this commodity, rather than whether the
  # version string on the row still matches it. An exists check rather than a
  # join, so nothing fans out and `currentVersion=false` stays the plain table.
  scope :current_version, ->(flag = true, source = ::ScData::Source.current) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(id: CommodityBuild.current(source).select(:commodity_id))
    else
      all
    end
  }

  # The build a filter resolves against, joined as `commodity_facts`. Two shapes
  # behind one alias, so a ransacker stays a single static expression either way.
  #
  # An inner join to the build we are on *is* `current_version`, so no column
  # fallback is needed on this path -- and leaving it out is what keeps the
  # filter on an indexed column. `COALESCE(build, column)` spans two tables, so
  # no index applies and every row has to be touched: measured on equipment when
  # this was first built the wrong way, 5.18ms against 0.13ms.
  def self.current_facts_join(source)
    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      INNER JOIN commodity_builds AS commodity_facts
        ON commodity_facts.commodity_id = commodities.id
       AND commodity_facts.environment = ?
       AND commodity_facts.version = ?
    SQL
  end

  # Everything: rows only an older build describes, and rows no load ever did.
  # The fallback is unavoidable here, so it is folded into the subquery rather
  # than into each condition -- the ransackers stay identical, and the cost lands
  # only on this path, which is `currentVersion=false` and the admin list.
  def self.all_facts_join(source)
    facts = CommodityBuild::FILTERABLE.map { |fact| "COALESCE(b.#{fact}, c.#{fact}) AS #{fact}" }.join(", ")

    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      LEFT JOIN (
        SELECT c.id AS commodity_id, #{facts}
        FROM commodities c
        LEFT JOIN (
          SELECT DISTINCT ON (commodity_id) *
          FROM commodity_builds
          WHERE environment = ?
          ORDER BY commodity_id, (version = ?) DESC, created_at DESC
        ) b ON b.commodity_id = c.id
      ) AS commodity_facts ON commodity_facts.commodity_id = commodities.id
    SQL
  end

  scope :with_facts, ->(current_only = true, source = ::ScData::Source.current) {
    joins(
      ActiveModel::Type::Boolean.new.cast(current_only) ? current_facts_join(source) : all_facts_join(source)
    )
  }

  # One fact, off whichever build the join supplied. Referencing the alias
  # without `with_facts` raises rather than returning the wrong rows, which is
  # the failure mode to want here -- ransack drops a condition it cannot place
  # without saying a word.
  def self.fact_sql(fact)
    Arel.sql("commodity_facts.#{fact}")
  end

  # Not in the build we are on. Said out loud in the API, which until now offered
  # a commodity the export had dropped as though it were current.
  def retired?
    build.blank?
  end

  # The build we are on, or the last one that described the commodity.
  def facts
    build || last_build
  end

  # An admin correction is a correction to the build we are on, so it has to
  # reach the build as well as the row.
  #
  # The next load overwrites it, and that is the point: the game files hold what
  # is actually in the game, so a wrong value here is a parser bug and the fix
  # belongs in the parser.
  def update_with_facts(attributes)
    transaction do
      return false unless update(attributes)

      facts_attributes = attributes.to_h.symbolize_keys.slice(*CommodityBuild::FACTS)

      # Reloaded rather than read off the association: validating the row above
      # consults a fact reader, which caches whatever the build was at that
      # moment -- a nil, for a row whose build is written afterwards.
      reload_build&.update!(facts_attributes) if facts_attributes.present?

      true
    end
  end

  # Read through the build, falling back to the column. The column still answers
  # for a commodity no load has given a build -- an admin can create one by hand,
  # and the UEX importer creates them too.
  CommodityBuild::READ_THROUGH.each do |fact|
    define_method(fact) do
      value = facts&.public_send(fact)

      value.nil? ? super() : value
    end
  end

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

  # Filtering and sorting read the build. Each of these shadows a real column of
  # the same name -- a ransacker wins over a column -- so every query parameter
  # keeps working untouched, with no API and no frontend change.
  CommodityBuild::FILTERABLE.each do |fact|
    ransacker(fact) { Commodity.fact_sql(fact) }
  end

  # Read off the build table rather than through the rows: the builds we are on
  # *are* the current catalogue, so this needs neither the join nor
  # `current_version` and stays a single index scan.
  def self.commodity_types(source = ::ScData::Source.current)
    CommodityBuild.current(source)
      .where.not(commodity_type: nil)
      .distinct
      .order(:commodity_type)
      .pluck(:commodity_type)
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
