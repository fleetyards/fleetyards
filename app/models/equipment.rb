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
#  volume                 :decimal(15, 6)
#  volume_dimensions      :jsonb
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
  attr_accessor :update_reason, :update_reason_description, :author_id

  # Only an admin action sets `author_id`, so a loader write files nothing. The
  # gate is not tidiness: the UEX sync rewrites all 232 commodities and 1,526 of
  # 4,830 equipment rows a week, and versioning those unconditionally would bury
  # the handful of real edits the way Fleet's touch versions already do.
  has_paper_trail on: %i[update],
    only: %i[
      name description equipment_type item_type sub_type weapon_class
      slot size grade rate_of_fire range storage volume damage_reduction
      temperature_rating radiation_protection radiation_scrub_rate
      g_force_tolerance core_compatibility backpack_compatibility
      manufacturer_id hidden sc_key sc_ref
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

  paginates_per 50

  belongs_to :manufacturer, optional: true

  # What each build of the game says about this item. Written alongside the
  # columns for now, so reads can move over a catalogue at a time.
  has_many :builds, class_name: "EquipmentBuild", dependent: :destroy
  has_one :build, -> { current }, class_name: "EquipmentBuild", inverse_of: :equipment

  # Whether the build we are on describes this item, rather than whether the
  # version string on the row still matches it. An exists check rather than a
  # join, so nothing fans out and `current_version(false)` stays the plain table.
  #
  # Overrides ScDataVersioned for equipment only; the other catalogues still
  # compare their column until they have builds of their own.
  scope :current_version, ->(flag = true, source = ::ScData::Source.current) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(id: EquipmentBuild.current(source).select(:equipment_id))
    else
      all
    end
  }

  # The build a filter resolves against, joined as `equipment_facts`. Two shapes
  # behind one alias, so a ransacker stays a single static expression either way.
  #
  # This one is the catalogue we are on, and an inner join to it *is*
  # `current_version`: a row the build describes has a build row, and a row it
  # does not describe is not in the catalogue. So no column fallback is needed
  # here -- and leaving it out is what keeps the filter on an indexed column.
  #
  # That matters more than it looks. `COALESCE(build, column)` spans two tables,
  # so no index applies and every row has to be touched: measured on 4821 rows,
  # 5.18ms against 0.13ms, with the plan turning from an index scan into a seq
  # scan. Here that is 5ms; on a big table it is the whole query.
  def self.current_facts_join(source)
    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      INNER JOIN equipment_builds AS equipment_facts
        ON equipment_facts.equipment_id = equipment.id
       AND equipment_facts.environment = ?
       AND equipment_facts.version = ?
    SQL
  end

  # Everything: rows only an older build describes, and rows no load ever did.
  # The fallback is unavoidable here, so it is folded into the subquery rather
  # than into each condition -- the ransackers stay identical, and the cost lands
  # only on this path, which is `currentVersion=false` and the admin list.
  def self.all_facts_join(source)
    facts = EquipmentBuild::FILTERABLE.map { |fact| "COALESCE(b.#{fact}, e.#{fact}) AS #{fact}" }.join(", ")

    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      LEFT JOIN (
        SELECT e.id AS equipment_id, #{facts}
        FROM equipment e
        LEFT JOIN (
          SELECT DISTINCT ON (equipment_id) *
          FROM equipment_builds
          WHERE environment = ?
          ORDER BY equipment_id, (version = ?) DESC, created_at DESC
        ) b ON b.equipment_id = e.id
      ) AS equipment_facts ON equipment_facts.equipment_id = equipment.id
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
    Arel.sql("equipment_facts.#{fact}")
  end

  # The newest build of this environment that still describes the item, which is
  # what a record the export dropped falls back to. Without it a retired item
  # would read as nameless, and an inventory entry pointing at one has to
  # resolve to something.
  has_one :last_build,
    -> { for_source.order(created_at: :desc) },
    class_name: "EquipmentBuild", inverse_of: :equipment

  # Not in the build we are on. Said out loud in the API, which until now offered
  # a record the export had dropped as though it were current.
  def retired?
    build.blank?
  end

  # The build we are on, or the last one that described the item.
  def facts
    build || last_build
  end

  # An admin correction is a correction to the build we are on, so it has to
  # reach the build as well as the row.
  #
  # The next load overwrites it, and that is the point: the game files hold what
  # is actually in the game, so a wrong value here is a parser bug, and the fix
  # belongs in the parser. Nothing is curated on equipment the way Model splits
  # its `rsi_*` columns from the ones a person maintains.
  def update_with_facts(attributes)
    transaction do
      return false unless update(attributes)

      facts_attributes = attributes.to_h.symbolize_keys.slice(*EquipmentBuild::FACTS)

      # Reloaded rather than read off the association: validating the row above
      # consults a fact reader, which caches whatever the build was at that
      # moment -- a nil, for a row whose build is written afterwards.
      reload_build&.update!(facts_attributes) if facts_attributes.present?

      true
    end
  end

  # Read through the build, falling back to the column. The column still answers
  # for a record no load has given a build -- an admin can create one by hand.
  EquipmentBuild::READ_THROUGH.each do |fact|
    define_method(fact) do
      value = facts&.public_send(fact)

      value.nil? ? super() : value
    end
  end

  # Nothing fills this from the game files: the loadout icons the records name
  # are art the export leaves out on purpose. It is here for the same reason
  # every other catalogue has one -- an upload, and the ledger's fallback to
  # the referenced item's picture.
  has_one_attached :store_image
  ransack_attachment :store_image

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
  # Filtering and sorting read the build, through the same fallback as the
  # readers. Each of these shadows a real column of the same name -- a ransacker
  # wins over a column, so every query parameter keeps working untouched.
  # `type` is what makes a comparison numeric or boolean rather than string-wise,
  # the same reason ItemPriceConcern passes it.
  FACT_RANSACK_TYPES = {
    rate_of_fire: :decimal, range: :decimal, storage: :decimal, hidden: :boolean
  }.freeze

  (EquipmentBuild::FILTERABLE - [:slot]).each do |fact|
    ransacker(fact, type: FACT_RANSACK_TYPES[fact]) { Equipment.fact_sql(fact) }
  end

  # Apart from the formatter, which turns the enum name a client sends into the
  # integer the column stores.
  ransacker :slot, formatter: proc { |v| Equipment.slots[v] } do
    Equipment.fact_sql(:slot)
  end

  enum :core_compatibility,
    {all: 0, medium_heavy: 1, heavy: 2},
    suffix: true

  enum :backpack_compatibility,
    {all: 0, light_medium: 1, light: 2},
    suffix: true

  def self.ransackable_attributes(_auth_object = nil)
    # Most of these are ransackers rather than columns now, and a ransacker that
    # is not whitelisted here is ignored -- ransack drops the condition without
    # a word. Removing a name from this list silently disables a filter.
    %w[
      id name slug sc_key equipment_type item_type sub_type weapon_class size grade
      slot hidden manufacturer_id range rate_of_fire storage store_image created_at updated_at
    ] + ItemPriceConcern::RANSACKABLE_ATTRIBUTES
  end

  def self.ransackable_associations(_auth_object = nil)
    ["manufacturer"]
  end

  # Joined rather than a plain where, because `hidden` now answers off the build.
  # `current_only` picks the join, and for the default it also narrows to the
  # catalogue: an inner join to the build we are on leaves out everything that
  # build does not describe, which is the work `current_version` did by hand.
  def self.visible(current_only = true, source = ::ScData::Source.current)
    with_facts(current_only, source).where(fact_sql(:hidden).eq(false))
  end

  def self.ordered_by_name
    visible.order(fact_sql(:name).asc)
  end

  # Read off the build table rather than through the rows: the builds we are on
  # *are* the current catalogue, so this needs neither the join nor
  # `current_version` and stays a single index scan.
  def self.build_facet(fact, source = ::ScData::Source.current)
    scope = EquipmentBuild.current(source).where(hidden: false).where.not(fact => nil)
    scope = yield(scope) if block_given?

    scope.distinct.order(fact).pluck(fact)
  end

  def self.equipment_types
    build_facet(:equipment_type)
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

  # Read off the table rather than from WEAPON_CLASSES for the same reason the
  # column is a free string: a class a patch introduces has to reach the picker
  # without waiting on the constant being updated.
  def self.weapon_classes
    build_facet(:weapon_class)
  end

  def self.weapon_class_filters
    weapon_classes.map do |item|
      Filter.new(
        category: "weapon_class",
        label: I18n.t("filter.equipment.weapon_class.items.#{item}", default: item.humanize),
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

  # A picker that only offers weapons has no use for the ninety-odd types the
  # armour and clothing rows contribute, so the caller can narrow by the game's
  # own split before the types are collected.
  def self.item_types(equipment_types = nil)
    build_facet(:item_type) do |scope|
      equipment_types.present? ? scope.where(equipment_type: equipment_types) : scope
    end
  end

  def self.item_type_filters(equipment_types = nil)
    item_types(equipment_types).map do |item|
      Filter.new(
        category: "item_type",
        label: I18n.t("filter.equipment.item_type.items.#{item}", default: item.humanize),
        value: item
      )
    end
  end
end
