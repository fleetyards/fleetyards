# frozen_string_literal: true

# A crafting recipe: what it makes, what it costs, and how good the materials
# have to be.
#
# A blueprint has no name of its own -- 1606 of the 1607 records in 4.10.1 carry
# `blueprintName="@LOC_PLACEHOLDER"` -- so `name` is copied from whatever the
# recipe produces. The slug is not: it comes from the record key, because three
# outputs carry two blueprints each and two recipes for the same shield cannot
# share a URL.
# == Schema Information
#
# Table name: blueprints
#
#  id             :uuid             not null, primary key
#  category_ref   :string
#  craft_time     :integer
#  craftable_type :string
#  name           :string
#  sc_key         :string           not null
#  sc_ref         :string           not null
#  slot_count     :integer
#  slug           :string           not null
#  version        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  craftable_id   :uuid
#
# Indexes
#
#  index_blueprints_on_craftable_type_and_craftable_id  (craftable_type,craftable_id)
#  index_blueprints_on_sc_key                           (sc_key) UNIQUE
#  index_blueprints_on_sc_ref                           (sc_ref) UNIQUE
#  index_blueprints_on_slug                             (slug) UNIQUE
#  index_blueprints_on_version                          (version)
#
class Blueprint < ApplicationRecord
  include SlugConcern
  include ScDataVersioned

  paginates_per 60

  # Component, Equipment or Commodity. Optional because 28 of the 1607 recipes
  # in 4.10.1 make something no catalogue here carries: 23 armour colourways and
  # weapon tints, four mission carryables, and one entity class that is in no
  # file in the export.
  belongs_to :craftable, polymorphic: true, optional: true

  # What each build of the game says about this blueprint.
  has_many :builds, class_name: "BlueprintBuild", dependent: :destroy
  # The build we are being served from, which is the configured one unless its
  # load has not run yet. `current` on its own means *exactly* the configured
  # build and has to keep meaning that -- `ScData::CheckJob` asks it whether the
  # new build has landed -- so the resolution happens here instead.
  #
  # Without it this association is empty for every row during that window, and
  # `retired?`, which is `build.blank?`, told every reader that everything in
  # the catalogue was no longer in the game.
  #
  # Resolved through `served_source`, which asks the question of *this*
  # catalogue, rather than through the global `served`. Blueprints are the
  # reason that distinction exists: they are the only catalogue with no rows in
  # 4.10.0 or 4.9.0, so a reader on one of those builds gets a global `served`
  # that blueprints cannot answer for. `facts` then falls back to the last build
  # that did describe the recipe while `build` stayed empty, and the page said
  # both -- the whole recipe, off 4.10.1, under the word "Retired".
  #
  # `current_version` has always resolved this way; this association was the one
  # place in the model that did not.
  has_one :build, -> { current(::Blueprint.served_source) }, class_name: "BlueprintBuild", inverse_of: :blueprint

  # The newest build of this environment that still describes the recipe, which
  # is what one the export dropped falls back to.
  has_one :last_build,
    -> { for_source.order(created_at: :desc) },
    class_name: "BlueprintBuild", inverse_of: :blueprint

  # Whether the build we are on describes this blueprint, rather than whether
  # the version string on the row still matches. An exists check rather than a
  # join, so nothing fans out.
  scope :current_version, ->(flag = true, source = ::ScData::Source.current) {
    if ActiveModel::Type::Boolean.new.cast(flag)
      where(id: BlueprintBuild.current(served_source(source)).select(:blueprint_id))
    else
      all
    end
  }

  # Recipes that consume a given material, in the build being read. Takes a
  # record or a relation, so one material and several work the same way.
  #
  # Three hops, written as an exists check rather than a join: a recipe naming
  # the same material in two slots would otherwise come back twice.
  scope :consuming, ->(commodity, source = ::ScData::Source.current, current_only: true) {
    where(
      id: readable_builds(source, current_only:).where(
        id: BlueprintCostSlot
          .where(id: BlueprintCostOption.where(commodity:).select(:blueprint_cost_slot_id))
          .select(:blueprint_build_id)
      ).select(:blueprint_id)
    )
  }

  # Through the build, like `consuming`: the columns on the row carry whatever
  # the last source to load wrote, so filtering them would answer a ptu request
  # with live's links.
  scope :making, ->(craftable, source = ::ScData::Source.current, current_only: true) {
    where(
      id: readable_builds(source, current_only:)
        .where(craftable_type: craftable.class.name, craftable_id: craftable.id)
        .select(:blueprint_id)
    )
  }

  # Recipes an org hands out, in the build we are on.
  scope :from_org, ->(org_name, source = ::ScData::Source.current, current_only: true) {
    where(
      id: readable_builds(source, current_only:)
        .where(id: BlueprintSource.where(org_name:).select(:blueprint_build_id))
        .select(:blueprint_id)
    )
  }

  # 875 of the 1607 recipes in 4.10.1 appear in no reward pool, and another 26
  # sit only in a pool nothing hands out. The page has to say so rather than
  # render an empty section, which reads as a bug.
  scope :with_known_source, ->(flag = true, source = ::ScData::Source.current, current_only: true) {
    known = readable_builds(source, current_only:)
      .where(id: BlueprintSource.select(:blueprint_build_id))
      .select(:blueprint_id)

    ActiveModel::Type::Boolean.new.cast(flag) ? where(id: known) : where.not(id: known)
  }

  # Recipes whose output the build actually names. 5 of the 1607 in 4.10.1
  # resolve to nothing -- four mission carryables that are in no catalogue and
  # one entity class that is in no file in the export -- and those five are the
  # rows an admin goes looking for after a load.
  #
  # Shaped like `with_known_source` and applied the same way, by the controller
  # rather than through ransack, for the reason recorded on `ransackable_scopes`:
  # ransack skips a scope whose value is false, so as a ransack scope this could
  # only ever mean "on".
  scope :with_craftable, ->(flag = true, source = ::ScData::Source.current, current_only: true) {
    resolved = readable_builds(source, current_only:)
      .where.not(craftable_id: nil)
      .select(:blueprint_id)

    ActiveModel::Type::Boolean.new.cast(flag) ? where(id: resolved) : where.not(id: resolved)
  }

  before_save :update_slugs

  validates :sc_ref, presence: true, uniqueness: true
  validates :sc_key, presence: true, uniqueness: true

  # The catalogues a recipe can make something in. Named here rather than in the
  # schema so the API enum and the association cannot drift apart.
  CRAFTABLE_TYPES = %w[Component Equipment Commodity].freeze

  DEFAULT_SORTING_PARAMS = ["name asc"]

  # `craftTime` is the one figure a crafter sorts by that is not a name -- "what
  # can I make quickly" -- and it is a fact, so it resolves off the joined build
  # like the rest.
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "craftTime asc", "craftTime desc",
    "createdAt asc", "createdAt desc"
  ]

  # The build a filter resolves against, joined as `blueprint_facts`. Two shapes
  # behind one alias, so a ransacker stays a single static expression either way.
  #
  # An inner join to the build we are on *is* `current_version`, so no column
  # fallback is needed on that path -- and leaving it out is what keeps the
  # filter on an indexed column rather than a two-table COALESCE.
  def self.current_facts_join(source)
    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      INNER JOIN blueprint_builds AS blueprint_facts
        ON blueprint_facts.blueprint_id = blueprints.id
       AND blueprint_facts.environment = ?
       AND blueprint_facts.version = ?
    SQL
  end

  # Everything: rows only an older build describes, and rows no load ever did.
  # The fallback is unavoidable here, so it is folded into the subquery rather
  # than into each condition -- the ransackers stay identical, and the cost
  # lands only on `currentVersion=false`.
  def self.all_facts_join(source)
    facts = BlueprintBuild::FILTERABLE.map { |fact| "COALESCE(b.#{fact}, p.#{fact}) AS #{fact}" }.join(", ")

    sanitize_sql_array([<<~SQL.squish, source.environment, source.version])
      LEFT JOIN (
        SELECT p.id AS blueprint_id, #{facts}
        FROM blueprints p
        LEFT JOIN (
          SELECT DISTINCT ON (blueprint_id) *
          FROM blueprint_builds
          WHERE environment = ?
          ORDER BY blueprint_id, (version = ?) DESC, created_at DESC
        ) b ON b.blueprint_id = p.id
      ) AS blueprint_facts ON blueprint_facts.blueprint_id = blueprints.id
    SQL
  end

  # One fact, off whichever build the join supplied. Referencing the alias
  # without `with_facts` raises rather than returning the wrong rows, which is
  # the failure mode to want -- ransack drops a condition it cannot place
  # without saying a word.
  def self.fact_sql(fact)
    Arel.sql("blueprint_facts.#{fact}")
  end

  BlueprintBuild::FILTERABLE.each do |fact|
    ransacker(fact) { Blueprint.fact_sql(fact) }
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id id_value name sc_key slug updated_at version craft_time craftable_type craftable_id]
  end

  # The build a read resolves through, for one source: the build we are on
  # where there is one, and the newest older build otherwise. Mirrors exactly
  # what `all_facts_join` picks, so a filter and the row it renders agree about
  # which build they are talking about.
  #
  # A filter pinned to the current build while the render falls back would drop
  # a retired recipe whose retained build does name the org being asked for --
  # and would let it through `withKnownSource=false` while its own response
  # said a source was known.
  def self.readable_builds(source = ::ScData::Source.current, current_only: true)
    return BlueprintBuild.current(source) if ActiveModel::Type::Boolean.new.cast(current_only)

    BlueprintBuild.from(
      BlueprintBuild.for_source(source)
        .select("DISTINCT ON (blueprint_id) blueprint_builds.*")
        .order(Arel.sql(sanitize_sql_array(["blueprint_id, (version = ?) DESC, created_at DESC", source.version]))),
      :blueprint_builds
    )
  end

  # `craftable` is deliberately not here. Ransack computes an association's
  # class to build the join, and a polymorphic one has none -- naming it raises
  # "Polymorphic associations do not support computing the class" the moment a
  # query touches it. What a filter actually wants is which catalogue the
  # output is in, and `craftable_type` is that, as a plain column.
  def self.ransackable_associations(auth_object = nil)
    %w[sources]
  end

  # `with_known_source` is deliberately absent, and cannot be added.
  #
  # Ransack converts a scope's "true"/"false" string to a boolean and then
  # applies the scope only when the value is truthy, so a boolean scope reached
  # through ransack can only ever mean "on": `withKnownSource=false` would
  # return the whole catalogue rather than the 901 recipes with no stated
  # source. Measured -- the scope answers 901 called directly and 1607 through
  # ransack, either spelling.
  #
  # `current_version` has the same shape and gets away with it, because the
  # controller reads that flag itself to pick the join and the scope is only a
  # redundant exists check. Here the flag *is* the filter, so the controller
  # takes it off the query and applies it directly, the way the commodities and
  # equipment endpoints already do for their version flag.
  # Only `current_version`, whose own controller reads the flag separately and
  # for which the scope is a redundant exists check.
  #
  # `from_org`, `consuming_commodity` and `with_known_source` all have to know
  # whether the request is reading the current build or falling back, and a
  # ransack scope is handed one argument. The controller applies all three.
  def self.ransackable_scopes(auth_object = nil)
    %w[current_version]
  end

  # Ransack hands a scope whatever the query names, so the commodity is looked
  # up by slug rather than taken as a record -- a filter is a URL, and a URL
  # cannot carry an ActiveRecord object.
  # Ransack hands a scope whatever the query names, so the material is looked
  # up by slug rather than taken as a record -- a filter is a URL, and a URL
  # cannot carry an ActiveRecord object.
  #
  # Several slugs mean "uses any of these", not "uses all of them": a recipe
  # has at most four slots, so asking for three materials at once would
  # almost always be asking for nothing.
  scope :consuming_commodity, ->(slugs, source = ::ScData::Source.current, current_only: true) {
    wanted = Array.wrap(slugs).map { |slug| slug.to_s.downcase }.reject(&:blank?)

    return none if wanted.blank?

    commodities = Commodity.where(slug: wanted)

    commodities.exists? ? consuming(commodities, source, current_only:) : none
  }

  # The recipe and the sources belong to the build, not to the blueprint: live
  # and ptu are loaded separately and either can be read, so one global set
  # would leave whichever tree loaded last answering for both.
  #
  # Read through `facts` rather than through `build` alone, so they take the
  # same fallback every scalar fact does. A retired recipe still has to render,
  # and a page showing a recipe with no ingredients -- or claiming nobody knows
  # where it comes from when the last build named four orgs -- reads as broken
  # rather than as retired.
  def cost_slots
    facts&.cost_slots || BlueprintCostSlot.none
  end

  def sources
    facts&.sources || BlueprintSource.none
  end

  def cost_options
    BlueprintCostOption.where(blueprint_cost_slot_id: cost_slots.select(:id)).order(:position)
  end

  # The materials this recipe consumes, named, in slot order and without
  # repeats. Read through `facts` like the recipe it comes from, so a retired
  # blueprint still lists what it took.
  def materials
    cost_slots
      .flat_map { |slot| slot.options.filter_map(&:commodity) }
      .uniq
  end

  # Nothing in the export says where this one comes from. Answered off the last
  # build that did describe it, so a recipe the current build dropped does not
  # read as one nobody ever knew a source for.
  def source_unknown?
    sources.empty?
  end

  # The build names no output at all. Read off the build rather than through the
  # `craftable` association, so it answers exactly what `with_craftable` filters
  # on -- a row the filter excludes can never render as one it includes.
  def craftable_missing?
    (facts || self).craftable_id.blank?
  end

  # The materials recipes in the build we are on actually consume, as filter
  # options. Sourced from the cost rows rather than from the commodity
  # catalogue: 37 of the 232 commodities appear in a recipe, and a select
  # offering the other 195 would be a filter that cannot match.
  #
  # Two things it has to agree with, and did not: the build a list is actually
  # answered from is the *served* one, not the configured one, and a caller
  # reading the fallback build has to be offered the materials that build
  # names. Both come from `readable_builds`, which is what the filters use.
  def self.material_filters(source = served_source, current_only: true)
    Commodity
      .where(
        id: BlueprintCostOption
          .where(
            blueprint_cost_slot_id: BlueprintCostSlot
              .where(blueprint_build_id: readable_builds(source, current_only:).select(:id))
              .select(:id)
          )
          .select(:commodity_id)
      )
      .order(:name)
      .map { |commodity| Filter.new(category: "material", label: commodity.name, value: commodity.slug) }
  end

  # The catalogues a recipe can make something in, as filter options. From the
  # constant rather than from a DISTINCT over the column: all three are always
  # offerable, and a type nothing currently makes is still a question worth
  # being able to ask.
  def self.craftable_type_filters
    CRAFTABLE_TYPES.map do |type|
      Filter.new(
        category: "craftable_type",
        label: I18n.t("filter.blueprint.craftable_type.items.#{type.underscore}", default: type),
        value: type
      )
    end
  end

  # The orgs whose missions hand a recipe out, in the build we are on. 130 of
  # the 154 reward pools carry an org and the other 24 carry a pool name alone,
  # so this is shorter than the pool list and every option it offers can match.
  def self.org_filters(source = served_source, current_only: true)
    BlueprintSource
      .where(blueprint_build_id: readable_builds(source, current_only:).select(:id))
      .where.not(org_name: nil)
      .distinct
      .order(:org_name)
      .pluck(:org_name)
      .map { |org| Filter.new(category: "org", label: org, value: org) }
  end

  # Not in the build we are on.
  def retired?
    build.blank?
  end

  # The build we are on, or the last one that described the recipe.
  def facts
    build || last_build
  end

  # What the recipe makes, as the build we are read for states it. The column is
  # written too, so search and sort stay single-table, but it holds whatever the
  # last source to load wrote -- and a blueprint is in both trees.
  def craftable
    facts.nil? ? super : facts.craftable
  end

  # Read through the build, and the build alone: a `nil` there is an answer, not
  # a gap to fill from the row.
  #
  # This is where Blueprint parts company with Commodity, Equipment and
  # Component, which do fall back to the column. They have to: an admin creates
  # commodities by hand and the UEX importer creates them too, so a row with no
  # build is a real case there. Every blueprint comes from a load, so the only
  # thing the fallback could do here is answer a ptu request with a live value --
  # which is exactly what it did for the three radars the game leaves nameless.
  BlueprintBuild::READ_THROUGH.each do |fact|
    define_method(fact) do
      facts.nil? ? super() : facts.public_send(fact)
    end
  end

  private def update_slugs
    # From the key rather than the name: 1607 records, 1604 distinct outputs,
    # and four recipes whose output has no name at all. `parameterize` leaves
    # an underscore alone, and every record key is written with them, so they
    # are swapped for the separator a URL reads with -- no key in 4.10.1
    # carries a dash of its own, so nothing collides by the swap.
    generate_slug(sc_key.delete_prefix("bp_craft_").tr("_", "-"))
  end
end
