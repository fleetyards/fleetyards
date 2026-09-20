# frozen_string_literal: true

require "test_helper"

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
class BlueprintTest < ActiveSupport::TestCase
  # From the key rather than the name: three outputs carry two blueprints each
  # in 4.10.1, and two recipes for the same shield cannot share a URL.
  test "generates a slug from the record key" do
    blueprint = create(:blueprint, sc_key: "bp_craft_klwe_smg_energy_01")

    assert_equal "klwe-smg-energy-01", blueprint.slug
  end

  test "two recipes for the same output keep their own slugs" do
    component = create(:component)
    first = create(:blueprint, sc_key: "bp_craft_shld_s04_890jump", craftable: component)
    second = create(:blueprint, sc_key: "bp_craft_shld_s04_polaris", craftable: component)

    assert_not_equal first.slug, second.slug
    assert_equal [component, component], [first.craftable, second.craftable]
  end

  test "rejects a duplicate ref" do
    create(:blueprint, sc_ref: "beef")
    duplicate = build(:blueprint, sc_ref: "beef")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :sc_ref
  end

  # 28 of the 1607 recipes in 4.10.1 make something no catalogue here carries.
  test "loads without a craftable" do
    blueprint = create(:blueprint, :without_craftable, name: "Probe")

    assert_predicate blueprint, :valid?
    assert_nil blueprint.craftable
  end

  test "#current_version narrows to the build we are on" do
    current = create(:blueprint)
    retired = create(:blueprint, :without_build, version: nil)

    assert_includes Blueprint.current_version, current
    assert_not_includes Blueprint.current_version, retired
    assert_includes Blueprint.current_version(false), retired
  end

  # Blueprints are the only catalogue with no rows in the older builds, so a
  # reader on one of those gets a global `served` this catalogue cannot answer
  # for. `facts` fell back to the last build that did describe the recipe while
  # `build` stayed empty, and the admin page rendered the whole recipe under the
  # word "Retired".
  # Blueprints are the only catalogue with no rows in the older builds, so a
  # reader on one of those gets a *global* served build this catalogue cannot
  # answer for. `facts` fell back to the last build that did describe the
  # recipe while `build` stayed empty, and the admin page rendered the whole
  # recipe under the word "Retired".
  #
  # The global `served` is overridden rather than staged: reproducing it with
  # real rows needs a build that is `complete?` for another catalogue and absent
  # from this one, which is a ledger fixture for something the association can
  # be asked directly.
  test "#build resolves through this catalogue's own served source" do
    blueprint = create(:blueprint)

    absent = ScData::Source.new(environment: ScData::Source.environment, version: "9.9.9-live.1")
    global = ScData::Source.new(environment: ScData::Source.environment, version: ScData::Source.version)
    global.define_singleton_method(:served) { absent }

    ScData::Source.with(global) do
      blueprint.reload

      # The build the association picks is the one every fact is read from.
      assert_equal blueprint.facts, blueprint.build
      assert_not_predicate blueprint, :retired?
    end
  end

  test "#retired? is true for a recipe the build no longer carries" do
    assert_not_predicate create(:blueprint), :retired?
    assert_predicate create(:blueprint, :without_build, version: nil), :retired?
  end

  # The build is what a reader sees, so an admin correction to the row alone
  # must not silently win over what the load wrote.
  test "reads its facts through the build" do
    blueprint = create(:blueprint, name: "Row Name")
    blueprint.build.update!(name: "Build Name", craft_time: 300)

    assert_equal "Build Name", blueprint.reload.name
    assert_equal 300, blueprint.craft_time
  end

  test "falls back to the column where no build describes it" do
    blueprint = create(:blueprint, :without_build, name: "Row Name", version: nil)

    assert_equal "Row Name", blueprint.name
  end

  # A recipe naming the same material in two slots has to come back once.
  test ".consuming finds each recipe that uses a commodity once" do
    commodity = create(:commodity)
    blueprint = create(:blueprint)
    2.times do |position|
      slot = create(:blueprint_cost_slot, build: blueprint.build, position:)
      create(:blueprint_cost_option, slot:, commodity:)
    end
    create(:blueprint)

    assert_equal [blueprint], Blueprint.consuming(commodity).to_a
  end

  # Live and ptu are loaded separately and either can be read, so one global
  # recipe would leave whichever tree loaded last supplying the costs for both.
  test ".consuming ignores a recipe another build states" do
    commodity = create(:commodity)
    blueprint = create(:blueprint)
    other = blueprint.builds.create!(environment: "ptu", version: "9.9.9-ptu.1")
    create(:blueprint_cost_option, slot: create(:blueprint_cost_slot, build: other), commodity:)

    assert_empty Blueprint.consuming(commodity)
    assert_empty blueprint.reload.cost_slots
  end

  test ".making finds the recipes for one output" do
    component = create(:component)
    blueprint = create(:blueprint, craftable: component)
    create(:blueprint, craftable: create(:component))

    assert_equal [blueprint], Blueprint.making(component).to_a
  end

  # The columns on the row carry whatever the last source to load wrote, so a
  # filter against them answers a ptu request with live's links.
  test ".making ignores an output only another build states" do
    component = create(:component)
    blueprint = create(:blueprint, :without_build, version: nil, craftable: component)
    blueprint.builds.create!(environment: "ptu", version: "9.9.9-ptu.1", craftable: component)

    assert_empty Blueprint.making(component)
  end

  test "#craftable comes from the build we are read for" do
    blueprint = create(:blueprint, craftable: create(:component))
    replacement = create(:equipment)
    blueprint.build.update!(craftable: replacement)

    assert_equal replacement, blueprint.reload.craftable
  end

  # A nil on the build is an answer, not a gap to fill from the row -- three
  # radars have no name in the game files at all, and falling back would have
  # served another source's name for them.
  test "a fact the build leaves empty does not fall back to the row" do
    blueprint = create(:blueprint, name: "Row Name")
    blueprint.build.update!(name: nil)

    assert_nil blueprint.reload.name
  end

  # 875 of the 1607 recipes in 4.10.1 are in no pool, and 26 more are only in a
  # pool nothing hands out. The page has to say so rather than render nothing.
  test "#source_unknown? is true where the export says nothing" do
    sourced = create(:blueprint)
    create(:blueprint_source, build: sourced.build)

    assert_not_predicate sourced.reload, :source_unknown?
    assert_predicate create(:blueprint), :source_unknown?
  end

  test ".with_known_source splits the catalogue both ways" do
    sourced = create(:blueprint)
    create(:blueprint_source, build: sourced.build)
    unsourced = create(:blueprint)

    assert_equal [sourced], Blueprint.with_known_source.to_a
    assert_equal [unsourced], Blueprint.with_known_source(false).to_a
  end

  test ".from_org finds each recipe an org hands out once" do
    blueprint = create(:blueprint)
    2.times { |n| create(:blueprint_source, build: blueprint.build, org_name: "Eckhart Security", position: n) }
    create(:blueprint_source, build: create(:blueprint).build, org_name: "Headhunters")

    assert_equal [blueprint], Blueprint.from_org("Eckhart Security").to_a
  end

  test ".from_alignment finds each recipe one side of the law hands out once" do
    blueprint = create(:blueprint)
    2.times { |n| create(:blueprint_source, build: blueprint.build, alignment: "outlaw", position: n) }
    create(:blueprint_source, build: create(:blueprint).build, alignment: "lawful")

    assert_equal [blueprint], Blueprint.from_alignment(["outlaw"]).to_a
  end

  # Both sides hand out the same pool often enough that asking for two has to
  # mean "reachable either way" rather than "handed out by both".
  test ".from_alignment takes several as a union" do
    lawful = create(:blueprint)
    create(:blueprint_source, build: lawful.build, alignment: "lawful")
    outlaw = create(:blueprint)
    create(:blueprint_source, build: outlaw.build, alignment: "outlaw")
    neutral = create(:blueprint)
    create(:blueprint_source, build: neutral.build, alignment: "neutral")

    assert_equal [lawful, outlaw].sort_by(&:id),
      Blueprint.from_alignment(["lawful", "outlaw"]).to_a.sort_by(&:id)
  end

  # The nine sources the export leaves unattributed carry no alignment, and the
  # filter cannot ask for them -- `with_known_source` is the question about
  # whether anything hands a recipe out.
  test ".from_alignment skips a source with no stated alignment" do
    create(:blueprint_source, :unattributed, build: create(:blueprint).build)

    assert_empty Blueprint.from_alignment(BlueprintSource::ALIGNMENTS)
  end

  # Nothing but the three can match, so a value that is not one of them narrows
  # to nothing rather than widening to the catalogue.
  test ".from_alignment answers nothing for a value it does not know" do
    blueprint = create(:blueprint)
    create(:blueprint_source, build: blueprint.build, alignment: "lawful")

    assert_empty Blueprint.from_alignment(["uee"])
    assert_empty Blueprint.from_alignment([])
    assert_equal [blueprint], Blueprint.from_alignment(["LAWFUL", "uee"]).to_a
  end

  # Sources belong to the build for the reason the recipe does: live and ptu
  # are loaded separately and either can be read.
  test ".from_org ignores a source only another build states" do
    blueprint = create(:blueprint, :without_build, version: nil)
    other = blueprint.builds.create!(environment: "ptu", version: "9.9.9-ptu.1")
    create(:blueprint_source, build: other, org_name: "Eckhart Security")

    assert_empty Blueprint.from_org("Eckhart Security")
    assert_empty blueprint.reload.sources
  end

  # The row keeps its last build so a retired recipe still resolves. Reading the
  # recipe and the sources through the current build alone made a retired one
  # look like a recipe with no ingredients that nobody knows a source for.
  test "a retired recipe still carries its recipe and its sources" do
    blueprint = create(:blueprint, :without_build, version: nil)
    last = blueprint.builds.create!(
      environment: ScData::Source.environment, version: "0.0.1-live.1", name: "Retired"
    )
    create(:blueprint_cost_slot, build: last)
    create(:blueprint_source, build: last, org_name: "Eckhart Security")
    # Something else has to carry the configured build. With nothing loaded at
    # it, `ScData::Source#served` falls back to the newest build there is --
    # which in a test that creates exactly one is the very build it means to
    # call retired.
    create(:blueprint, :without_build).builds.create!(
      environment: ScData::Source.environment, version: ScData::Source.version
    )

    blueprint.reload

    assert_predicate blueprint, :retired?
    assert_equal 1, blueprint.cost_slots.count
    assert_equal 1, blueprint.sources.count
    assert_not_predicate blueprint, :source_unknown?
  end

  test "a blueprint no build has ever described reads as empty rather than raising" do
    blueprint = create(:blueprint, :without_build, version: nil)

    assert_empty blueprint.cost_slots
    assert_empty blueprint.sources
    assert_empty blueprint.cost_options
    assert_predicate blueprint, :source_unknown?
  end

  test "#cost_options reaches the options of the build being read" do
    blueprint = create(:blueprint)
    slot = create(:blueprint_cost_slot, build: blueprint.build)
    option = create(:blueprint_cost_option, slot:)

    assert_equal [option], blueprint.reload.cost_options.to_a
  end

  # A filter pinned to the current build while the render falls back drops a
  # retired recipe whose retained build does name the org being asked for.
  test ".from_org reaches the fallback build when the current one is gone" do
    blueprint = create(:blueprint, :without_build, version: nil)
    last = blueprint.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")
    create(:blueprint_source, build: last, org_name: "Eckhart Security")

    assert_empty Blueprint.from_org("Eckhart Security")
    assert_equal [blueprint], Blueprint.from_org("Eckhart Security", ScData::Source.current, current_only: false).to_a
  end

  test ".from_alignment reaches the fallback build when the current one is gone" do
    blueprint = create(:blueprint, :without_build, version: nil)
    last = blueprint.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")
    create(:blueprint_source, build: last, alignment: "outlaw")

    assert_empty Blueprint.from_alignment(["outlaw"])
    assert_equal [blueprint],
      Blueprint.from_alignment(["outlaw"], ScData::Source.current, current_only: false).to_a
  end

  # And the same recipe must not read as sourceless under the fallback, which
  # would contradict its own rendered response.
  test ".with_known_source reaches the fallback build too" do
    blueprint = create(:blueprint, :without_build, version: nil)
    last = blueprint.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")
    create(:blueprint_source, build: last)

    assert_equal [blueprint], Blueprint.with_known_source(true, ScData::Source.current, current_only: false).to_a
    assert_empty Blueprint.with_known_source(false, ScData::Source.current, current_only: false)
  end

  # The 5 recipes whose output is in no catalogue are the rows an admin goes
  # looking for after a load, so the scope has to answer both halves -- and
  # false is the half a ransack scope would silently skip.
  test ".with_craftable splits the catalogue both ways" do
    makes = create(:blueprint, :for_component)
    makes_nothing = create(:blueprint, :without_craftable)

    assert_equal [makes], Blueprint.with_craftable.to_a
    assert_equal [makes_nothing], Blueprint.with_craftable(false).to_a
  end

  # Through the build, like every other fact: the column holds whatever the
  # last source to load wrote, and a blueprint is in both trees.
  test ".with_craftable reads the build rather than the column" do
    blueprint = create(:blueprint, :for_component)
    blueprint.build.update!(craftable: nil)

    assert_empty Blueprint.with_craftable
    assert_equal [blueprint], Blueprint.with_craftable(false).to_a
  end

  test ".with_craftable reaches the fallback build too" do
    blueprint = create(:blueprint, :without_build, version: nil, craftable: create(:component))
    blueprint.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")

    assert_empty Blueprint.with_craftable
    assert_empty Blueprint.with_craftable(true, ScData::Source.current, current_only: false)
    assert_equal [blueprint], Blueprint.with_craftable(false, ScData::Source.current, current_only: false).to_a
  end

  # A row the filter excludes must never render as one it includes, so the
  # predicate reads the same build the scope does.
  test "#craftable_missing? agrees with .with_craftable" do
    blueprint = create(:blueprint, :for_component)

    assert_not_predicate blueprint, :craftable_missing?

    blueprint.build.update!(craftable: nil)

    assert_predicate blueprint.reload, :craftable_missing?
  end

  test ".craftable_type_filters offers every catalogue, labelled" do
    filters = Blueprint.craftable_type_filters

    assert_equal Blueprint::CRAFTABLE_TYPES, filters.map(&:value)
    assert(filters.all? { |filter| filter.label.present? })
  end

  # An unattributed pool contributes no option rather than a blank one.
  test ".org_filters names each org once and skips the unattributed" do
    build = create(:blueprint).build
    create(:blueprint_source, build:, org_name: "Eckhart Security", position: 1)
    create(:blueprint_source, build:, org_name: "Eckhart Security", position: 2)
    create(:blueprint_source, :unattributed, build:, position: 3)

    assert_equal ["Eckhart Security"], Blueprint.org_filters.map(&:value)
  end

  test ".consuming reaches the fallback build too" do
    commodity = create(:commodity)
    blueprint = create(:blueprint, :without_build, version: nil)
    last = blueprint.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")
    create(:blueprint_cost_option, slot: create(:blueprint_cost_slot, build: last), commodity:)

    assert_empty Blueprint.consuming(commodity)
    assert_equal [blueprint], Blueprint.consuming(commodity, ScData::Source.current, current_only: false).to_a
  end

  test "destroying a blueprint takes its builds, recipes and sources with it" do
    blueprint = create(:blueprint)
    slot = create(:blueprint_cost_slot, build: blueprint.build)
    create(:blueprint_cost_option, slot:)
    create(:blueprint_cost_modifier, slot:)

    create(:blueprint_source, build: blueprint.build)

    assert_difference -> { BlueprintBuild.count } => -1,
      -> { BlueprintCostSlot.count } => -1,
      -> { BlueprintCostOption.count } => -1,
      -> { BlueprintCostModifier.count } => -1,
      -> { BlueprintSource.count } => -1 do
      blueprint.destroy
    end
  end

  test ".owned_by is the recipes a holder has, and .not_owned_by its complement" do
    user = create(:user)
    held = create(:blueprint)
    other = create(:blueprint)
    create(:user_blueprint, user:, blueprint: held)

    assert_equal [held], Blueprint.owned_by(user).to_a
    assert_equal [other], Blueprint.not_owned_by(user).to_a
  end

  # The fleet list asks the same scope with a set of members rather than with
  # one person, which is the whole reason it takes a condition rather than a
  # user.
  test ".owned_by takes several holders" do
    first = create(:user)
    second = create(:user)
    held = create(:blueprint)
    also_held = create(:blueprint)
    create(:blueprint)

    create(:user_blueprint, user: first, blueprint: held)
    create(:user_blueprint, user: second, blueprint: also_held)

    assert_equal [held, also_held].map(&:id).sort,
      Blueprint.owned_by(User.where(id: [first.id, second.id])).pluck(:id).sort
  end

  # A recipe held by two people is one row in the list, not two -- which a join
  # would not have given.
  test ".owned_by lists a recipe two holders have once" do
    first = create(:user)
    second = create(:user)
    held = create(:blueprint)

    create(:user_blueprint, user: first, blueprint: held)
    create(:user_blueprint, user: second, blueprint: held)

    assert_equal [held], Blueprint.owned_by(User.where(id: [first.id, second.id])).to_a
  end

  # Signed out, "mine" is empty and "not mine" is the catalogue -- the two
  # sides of the filter do not answer symmetrically, on purpose.
  test ".owned_by is empty without a holder, and .not_owned_by is everything" do
    blueprint = create(:blueprint)

    assert_empty Blueprint.owned_by(nil)
    assert_equal [blueprint], Blueprint.not_owned_by(nil).to_a
  end

  test "destroying a blueprint takes the marks on it with it" do
    blueprint = create(:blueprint)
    create(:user_blueprint, blueprint:)

    assert_difference -> { UserBlueprint.count } => -1 do
      blueprint.destroy
    end
  end
end
