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
  has_one :build, -> { current }, class_name: "BlueprintBuild", inverse_of: :blueprint

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
      where(id: BlueprintBuild.current(source).select(:blueprint_id))
    else
      all
    end
  }

  # Recipes that consume a given commodity, in the build we are on. Three hops,
  # so it is written as an exists check rather than a join: a recipe naming the
  # same material in two slots would otherwise come back twice.
  scope :consuming, ->(commodity, source = ::ScData::Source.current) {
    where(
      id: BlueprintBuild.current(source).where(
        id: BlueprintCostSlot
          .where(id: BlueprintCostOption.where(commodity:).select(:blueprint_cost_slot_id))
          .select(:blueprint_build_id)
      ).select(:blueprint_id)
    )
  }

  # Through the build, like `consuming`: the columns on the row carry whatever
  # the last source to load wrote, so filtering them would answer a ptu request
  # with live's links.
  scope :making, ->(craftable, source = ::ScData::Source.current) {
    where(
      id: BlueprintBuild.current(source)
        .where(craftable_type: craftable.class.name, craftable_id: craftable.id)
        .select(:blueprint_id)
    )
  }

  # Recipes an org hands out, in the build we are on.
  scope :from_org, ->(org_name, source = ::ScData::Source.current) {
    where(
      id: BlueprintBuild.current(source)
        .where(id: BlueprintSource.where(org_name:).select(:blueprint_build_id))
        .select(:blueprint_id)
    )
  }

  # 875 of the 1607 recipes in 4.10.1 appear in no reward pool, and another 26
  # sit only in a pool nothing hands out. The page has to say so rather than
  # render an empty section, which reads as a bug.
  scope :with_known_source, ->(flag = true, source = ::ScData::Source.current) {
    known = BlueprintBuild.current(source)
      .where(id: BlueprintSource.select(:blueprint_build_id))
      .select(:blueprint_id)

    ActiveModel::Type::Boolean.new.cast(flag) ? where(id: known) : where.not(id: known)
  }

  before_save :update_slugs

  validates :sc_ref, presence: true, uniqueness: true
  validates :sc_key, presence: true, uniqueness: true

  DEFAULT_SORTING_PARAMS = ["name asc"]

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

  # Nothing in the export says where this one comes from. Answered off the last
  # build that did describe it, so a recipe the current build dropped does not
  # read as one nobody ever knew a source for.
  def source_unknown?
    sources.empty?
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
