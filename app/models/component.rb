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
#  required_tags         :string
#  sc_key                :string
#  sc_ref                :string
#  size                  :string(255)
#  slug                  :string
#  tags                  :string
#  tracking_signal       :integer
#  type_data             :jsonb
#  version               :string
#  created_at            :datetime
#  updated_at            :datetime
#  manufacturer_id       :uuid
#
# Indexes
#
#  index_components_on_manufacturer_id  (manufacturer_id)
#  index_components_on_name             (name)
#  index_components_on_sc_key           (sc_key) UNIQUE
#  index_components_on_slug             (slug) UNIQUE
#  index_components_on_version          (version)
#
class Component < ApplicationRecord
  include ActiveStorageVariants
  include AttachmentRansackers
  include ItemPriceConcern
  include ScDataVersioned

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
  attr_accessor :update_reason, :update_reason_description, :author_id

  # No `if:` guard, unlike the models versioned alongside this one: Component
  # already records loader changes and its history page shows them. This adds
  # the author the record never carried, nothing else.
  has_paper_trail on: %i[update],
    only: %i[
      name description size grade item_type item_class component_class component_sub_type
      component_type type_data durability power_connection heat_connection ammunition
      inventory_consumption tracking_signal manufacturer_id hidden
    ],
    version: :paper_trail_version,
    versions: {name: :paper_trail_versions},
    meta: {
      author_id: :author_id,
      reason: :update_reason,
      reason_description: :update_reason_description
    }

  # The tags an item carries and the tags it demands of the port it goes into.
  # A port and the item that fits it name a shared tag -- how the Eclipse's
  # ordnance port takes its own bomb racks and not the Gladiator's. Stored as a
  # serialised array, the way `Hardpoint#types` is.
  serialize :tags, type: Array, coder: JSON
  serialize :required_tags, type: Array, coder: JSON

  belongs_to :manufacturer, optional: true

  # What each build of the game says about this component. Written alongside the
  # columns for now, so reads can move over a catalogue at a time.
  has_many :builds, class_name: "ComponentBuild", dependent: :destroy
  has_one :build, -> { current }, class_name: "ComponentBuild", inverse_of: :component

  # The newest build of this environment that still describes the component,
  # which is what a record the export dropped falls back to. Without it a retired
  # component would read as nameless, and a hardpoint or a paint pointing at one
  # has to resolve to something.
  has_one :last_build,
    -> { for_source.order(created_at: :desc) },
    class_name: "ComponentBuild", inverse_of: :component

  # Whether the build we are on describes this component, rather than whether the
  # version string on the row still matches it. An exists check rather than a
  # join, so nothing fans out and `currentVersion=false` stays the plain table.
  #
  # Overrides ScDataVersioned for components only. Unlike equipment this scope is
  # reachable through ransack -- see `ransackable_scopes` -- which passes the flag
  # as its single argument, so the source stays a defaulted second parameter.
  scope :current_version, ->(flag = true, source = ::ScData::Source.current) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(id: ComponentBuild.current(served_source(source)).select(:component_id))
    else
      all
    end
  }

  # The build a filter resolves against, joined as `component_facts`. Two shapes
  # behind one alias, so a ransacker stays a single static expression either way.
  #
  # This one is the catalogue we are on, and an inner join to it *is*
  # `current_version`: a row the build describes has a build row, and a row it
  # does not describe is not in the catalogue. So no column fallback is needed
  # here -- and leaving it out is what keeps the filter on an indexed column.
  #
  # `COALESCE(build, column)` spans two tables, so no index applies and every row
  # has to be touched. Measured on equipment when this was first built the wrong
  # way: 5.18ms against 0.13ms, an index scan turning into a seq scan. Components
  # are eight thousand rows against equipment's five, so the same mistake costs
  # more here.
  def self.current_facts_join(source)
    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      INNER JOIN component_builds AS component_facts
        ON component_facts.component_id = components.id
       AND component_facts.environment = ?
       AND component_facts.version = ?
    SQL
  end

  # Everything: rows only an older build describes, and rows no load ever did.
  # The fallback is unavoidable here, so it is folded into the subquery rather
  # than into each condition -- the ransackers stay identical, and the cost lands
  # only on this path, which is `currentVersion=false` and the admin list.
  def self.all_facts_join(source)
    facts = ComponentBuild::FILTERABLE.map { |fact| "COALESCE(b.#{fact}, c.#{fact}) AS #{fact}" }.join(", ")

    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      LEFT JOIN (
        SELECT c.id AS component_id, #{facts}
        FROM components c
        LEFT JOIN (
          SELECT DISTINCT ON (component_id) *
          FROM component_builds
          WHERE environment = ?
          ORDER BY component_id, (version = ?) DESC, created_at DESC
        ) b ON b.component_id = c.id
      ) AS component_facts ON component_facts.component_id = components.id
    SQL
  end

  # One fact, off whichever build the join supplied. Referencing the alias
  # without `with_facts` raises rather than returning the wrong rows, which is
  # the failure mode to want here -- ransack drops a condition it cannot place
  # without saying a word.
  def self.fact_sql(fact)
    Arel.sql("component_facts.#{fact}")
  end

  # Not in the build we are on. Said out loud in the API, which until now offered
  # a component the export had dropped as though it were current.
  def retired?
    build.blank?
  end

  # The build we are on, or the last one that described the component.
  def facts
    build || last_build
  end

  # An admin correction is a correction to the build we are on, so it has to
  # reach the build as well as the row.
  #
  # The next load overwrites it, and that is the point: the game files hold what
  # is actually in the game, so a wrong value here is a parser bug and the fix
  # belongs in the parser. Nothing is curated on components the way Model splits
  # its `rsi_*` columns from the ones a person maintains.
  def update_with_facts(attributes)
    transaction do
      return false unless update(attributes)

      facts_attributes = attributes.to_h.symbolize_keys.slice(*ComponentBuild::FACTS)

      # Reloaded rather than read off the association: validating the row above
      # consults a fact reader, which caches whatever the build was at that
      # moment -- a nil, for a row whose build is written afterwards.
      reload_build&.update!(facts_attributes) if facts_attributes.present?

      true
    end
  end

  # Read through the build, falling back to the column. The column still answers
  # for a component no load has given a build -- an admin can create one by hand.
  # `description` is handled on its own below -- defining it here and again
  # afterwards would replace this reader rather than wrap it, and the column it
  # then fell back to is the one the old normaliser mangled.
  (ComponentBuild::READ_THROUGH - [:description]).each do |fact|
    define_method(fact) do
      value = facts&.public_send(fact)

      value.nil? ? super() : value
    end
  end

  # Reads through like the rest, then strips the metadata block the export
  # prefixes the prose with -- "Item Type: Quantum Drive\nManufacturer: ...".
  # Normalising only on save left every row loaded before that change still
  # serving the preamble; doing it here fixes what is already stored too, and is
  # idempotent for a value the save path has already cleaned.
  def description
    value = facts&.description
    value = super if value.nil?

    self.class.split_description(value).first
  end

  has_many :model_paints, dependent: :nullify

  has_many :hardpoints, as: :parent, dependent: :destroy, autosave: true
  has_many :hardpoint_loadouts, class_name: "Hardpoint", dependent: :nullify

  before_save :update_slugs
  before_save :extract_data_from_description

  # Kept apart from store_image, which is curated -- an admin upload or what the
  # hangar sync brought in. A load owns the icon and nothing else, so it can
  # rewrite artwork on every build without ever touching the curated picture.
  has_one_attached :icon
  has_one_attached :store_image
  ransack_attachment :store_image

  # jsonb, not a YAML string: every metric a component has lives in here,
  # and as text none of it could be filtered, sorted or indexed on. The
  # type keeps indifferent access, which the readers already assume.
  attribute :type_data, Types::IndifferentJson.new
  serialize :durability, coder: YAML
  serialize :power_connection, coder: YAML
  serialize :heat_connection, coder: YAML
  serialize :ammunition, coder: YAML
  serialize :inventory_consumption, coder: YAML

  # The metrics worth ordering a catalogue by, and the `type_data` key each one
  # lives under. Read off the component's own column rather than the joined
  # build: the loader writes both, so for a current component they agree, and
  # for a retired one the column still holds the last figures anyone measured.
  # The fallback join carries only `FILTERABLE`, which leaves `type_data` out,
  # so reading the build here would break `currentVersion=false`.
  #
  # Every value is a number in the export; `::numeric` is what makes Postgres
  # order them as such rather than as text, where "9" outranks "10".
  METRICS = {
    "maxHealth" => "max_health",
    "maxRegen" => "max_regen",
    "jumpRange" => "jump_range",
    "driveSpeed" => "drive_speed",
    "coolingRate" => "cooling_rate",
    "powerBase" => "power_base",
    "health" => "health",
    "thrustCapacity" => "thrust_capacity"
  }.freeze

  DEFAULT_SORTING_PARAMS = ["name asc", "created_at asc"]

  # Grade sorts off the joined build like every other fact. The metrics reach
  # inside `type_data`, which only became sortable when it stopped being a YAML
  # string -- "shields by max health" is the question a catalogue exists to
  # answer, and until now no amount of paging could ask it.
  #
  # `size` is deliberately absent. The column is a string holding "10" and "12"
  # beside "M" and "S", so ordering it puts 10 and 12 ahead of 2 -- and a sort
  # that reads as broken is worse than one not offered. It needs a numeric
  # ransacker of its own, which would change what `size_eq` matches.
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "grade asc", "grade desc",
    "createdAt asc", "createdAt desc"
  ] + METRICS.keys.flat_map { |metric| ["#{metric} asc", "#{metric} desc"] }

  def self.ordered_by_name
    order(name: :asc)
  end

  enum :item_class,
    {stealth: 0, civilian: 1, industrial: 2, military: 3, competition: 4}

  enum :tracking_signal,
    {infrared: 0, cross_section: 1, electromagnetic: 2}

  # `type` is what makes a comparison boolean rather than string-wise, the same
  # reason ItemPriceConcern passes it.
  FACT_RANSACK_TYPES = {hidden: :boolean}.freeze

  # Filtering and sorting read the build. Each of these shadows a real column of
  # the same name -- a ransacker wins over a column -- so every query parameter
  # keeps working untouched, with no API or frontend change.
  (ComponentBuild::FILTERABLE - %i[item_class tracking_signal]).each do |fact|
    ransacker(fact, type: FACT_RANSACK_TYPES[fact]) { Component.fact_sql(fact) }
  end

  # One ransacker per metric, so `q[sorts]=maxHealth desc` and
  # `q[maxHealth_gteq]=1000` both resolve. Only possible since `type_data`
  # stopped being a YAML string -- as text no SQL could reach a figure inside it.
  METRICS.each do |name, key|
    ransacker(name.underscore.to_sym, type: :float) do
      Arel.sql("(components.type_data ->> #{connection.quote(key)})::numeric")
    end
  end

  # The two enums keep their formatters, which turn the name a client sends into
  # the integer the column stores.
  ransacker :item_class, formatter: proc { |v| Component.item_classes[v] } do
    Component.fact_sql(:item_class)
  end

  ransacker :tracking_signal, formatter: proc { |v| Component.tracking_signals[v] } do
    Component.fact_sql(:tracking_signal)
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "ammunition", "category", "component_class", "component_sub_type", "component_type",
      "created_at", "description", "durability", "grade",
      "heat_connection", "hidden", "id", "id_value", "item_class", "item_type", "manufacturer_id", "name",
      "power_connection", "size", "slug", "store_image", "tracking_signal",
      "type_data", "updated_at", "version"
    ] + ItemPriceConcern::RANSACKABLE_ATTRIBUTES + METRICS.keys.map(&:underscore)
  end

  # `shop_commodities` was listed here long after the association was removed,
  # so any filter naming it raised rather than matching nothing.
  def self.ransackable_associations(auth_object = nil)
    ["manufacturer"]
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

  # Read off the build table rather than through the rows: the builds we are on
  # *are* the current catalogue, so this needs neither the join nor
  # `current_version` and stays a single index scan.
  def self.build_facet(fact, source = ::ScData::Source.current)
    scope = ComponentBuild.current(source).where.not(fact => nil)
    scope = yield(scope) if block_given?

    scope.distinct.pluck(fact).compact_blank.sort
  end

  def self.categories
    build_facet(:category)
  end

  def self.sub_types(category: nil)
    build_facet(:component_sub_type) do |scope|
      category.present? ? scope.where(category:) : scope
    end
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

  # Admin only -- the public endpoint is gone, because no component in the
  # current build carries this column. `pluck` rather than loading all 8,740
  # rows to read one attribute off each.
  def self.class_filters
    distinct.pluck(:component_class).compact.sort.map do |item|
      Filter.new(
        category: "class",
        label: I18n.t("filter.component.class.items.#{item.downcase}"),
        value: item
      )
    end
  end

  # The export prefixes a component's prose with a metadata block -- "Item Type",
  # "Manufacturer", "Size", "Grade", "Class" -- separated from it by a blank
  # line, and escapes its newlines as a literal backslash-n. Returns the prose
  # and that block, either of which can be absent.
  def self.split_description(value)
    return [nil, nil] if value.blank?

    text = value.gsub("\\n", "\n")
    head, rest = text.split("\n\n", 2)

    # Only a head that is actually the export's block counts as one. Taking the
    # first segment on faith discarded the opening paragraph of any ordinary
    # multi-paragraph description -- and the save callbacks then stored the
    # truncation, so the text was gone for good.
    prose, data = metadata_block?(head) ? [rest, head] : [text, nil]

    # Runs of whitespace collapse to one space -- the export wraps a paragraph
    # across lines.
    [prose&.gsub(/\s+/, " ")&.strip.presence, data]
  end

  # A head is the export's block when every line reads as a short "Key: value"
  # pair. Length is what separates one from prose: a metadata value is a size, a
  # grade or a measurement, while a paragraph that happens to open with a colon
  # ("Warning: do not ...") runs long.
  #
  # Keyed on shape rather than a list of known keys -- the blocks carry far more
  # than "Item Type" and "Manufacturer" ("Capacity", "Max Angle", "Full Strength
  # Distance"), and a list would publish every unlisted one as prose.
  # `[[:space:]]` rather than `\s`: the export separates a key from its value
  # with a non-breaking space often enough to matter -- "Class:\u00A0Competition"
  # -- and `\s` does not match one, so the block failed on its last line and the
  # whole thing published as prose.
  METADATA_LINE = /\A[A-Z][A-Za-z ]{0,40}:[[:space:]]\S/
  METADATA_LINE_MAX = 60

  def self.metadata_block?(head)
    return false if head.blank?

    lines = head.split("\n").map(&:strip).reject(&:empty?)
    return false if lines.empty?

    lines.all? { |line| line.length <= METADATA_LINE_MAX && line.match?(METADATA_LINE) }
  end

  def extract_data_from_description
    return if description.blank?

    cleaned_description, data = self.class.split_description(description)

    self.description = cleaned_description

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

  # The default derivation is `name.parameterize` with nothing to break a tie,
  # and a component's name is routinely shared -- every ship with a manned
  # turret contributes another "Manned Turret". `sc_key` is the only field that
  # separates them, and unlike a counter it survives a reload, so the URL a
  # visitor bookmarked still resolves after the next patch.
  #
  # The backfill suffixes *every* member of a shared base, so the assignment
  # does not depend on load order -- which row goes first differs between
  # production and a restored dump. Afterwards the rule relaxes on purpose: a
  # duplicate arriving in a later patch takes the suffix and the incumbent
  # keeps the URL it already has, because re-slugging a page people have
  # bookmarked is worse than the pair reading inconsistently. `slug_settled?`
  # is what holds the incumbent still.
  #
  # Picking a free slug and writing it are separate statements, so two writers
  # racing on the same new name can choose the same one. The unique index is
  # the guarantee: the loser raises `RecordNotUnique` rather than quietly
  # taking the other's URL. Not retried here -- a load is serial within a run,
  # and the admin path would need two people renaming onto the same name in the
  # same instant.
  private def update_slugs
    base = self.class.slug_for(name)
    return if slug_settled?(base)

    if base.blank?
      self.slug = nil
      return
    end

    self.slug = base
    return unless slug_base_shared? || slug_taken?

    if sc_key.present?
      self.slug = keyed_slug(base)
      return unless slug_taken?
    end

    suffix = 1
    loop do
      suffix += 1
      self.slug = "#{base}-#{suffix}"
      break unless slug_taken?
    end
  end

  # Whether the slug already reads as one this name would produce, which makes
  # the two existence checks below a pair of queries spent to rewrite the value
  # already in the column. A load saves every component it sees -- 8,740 of
  # them -- and renames a handful.
  #
  # Deliberately *not* `will_save_change_to_name?`: `name` reads through to the
  # build, and `apply_build` writes that after the row is saved, so a rename
  # lands in the slug one save late. Comparing against the name the reader
  # gives now is what lets that catch up; keying off the column's own change
  # would freeze the stale slug for good.
  private def slug_settled?(base)
    return false unless persisted? && slug.present? && base.present?

    slug == base || slug == keyed_slug(base) || slug.match?(/\A#{Regexp.escape(base)}-\d+\z/)
  end

  private def keyed_slug(base)
    return if sc_key.blank?

    "#{base}-#{self.class.slug_for(sc_key.tr("_", "-"))}"
  end

  private def slug_base_shared?
    self.class.where(name:).where.not(id:).exists?
  end

  private def slug_taken?
    self.class.where(slug:).where.not(id:).exists?
  end
end
