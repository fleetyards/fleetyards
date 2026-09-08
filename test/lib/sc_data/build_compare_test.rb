# frozen_string_literal: true

require "test_helper"

module ScData
  class BuildCompareTest < ActiveSupport::TestCase
    OLD = ::ScData::Source.new(environment: "live", version: "1.0.0-live.1")
    NEW = ::ScData::Source.new(environment: "live", version: "1.0.1-live.2")
    PTU = ::ScData::Source.new(environment: "ptu", version: "1.0.2-ptu.3")

    private def compare(from: OLD, to: NEW)
      ::ScData::BuildCompare.new(ComponentBuild, from:, to:).call
    end

    private def build_for(source, component: nil, **facts)
      create(:component_build,
        component: component || create(:component, :without_build),
        environment: source.environment, version: source.version, **facts)
    end

    # --- What moved ------------------------------------------------------------

    test "#call reports a record the newer build describes and the older one does not" do
      arrived = build_for(NEW).component
      build_for(OLD)

      assert_equal [arrived.id], compare.appeared
    end

    # "Vanished" means the newer build has no row for it, not that anything was
    # deleted: a catalogue row the export drops keeps its row and loses its build.
    test "#call reports a record the newer build stopped describing" do
      gone = build_for(OLD).component
      # A second record both builds describe, so the catalogue counts as
      # recorded on either side and the rule below is the one under test.
      build_for(NEW, component: build_for(OLD).component)

      assert_equal [gone.id], compare.vanished
      assert Component.exists?(gone.id), "the record itself is still there"
    end

    test "#call names the facts that differ on a record both builds describe" do
      component = create(:component, :without_build)
      build_for(OLD, component:, name: "Old Name", size: "2")
      build_for(NEW, component:, name: "New Name", size: "4")

      change = compare.changed.sole

      assert_equal component.id, change.id
      assert_equal "New Name", change.name
      assert_equal %i[name size], change.fields.sort
    end

    test "#call leaves out a record neither build changed" do
      component = create(:component, :without_build)
      build_for(OLD, component:, name: "Same")
      build_for(NEW, component:, name: "Same")

      assert_empty compare.changed
    end

    # --- The axis the recorded change log cannot reach --------------------------

    # `ModelBuildChange` diffs a build against the one before it in the same
    # environment, so it never answers this. Both builds are present at once, so
    # the answer is a query rather than a table.
    test "#call compares across environments" do
      only_in_ptu = build_for(PTU).component
      build_for(NEW)

      result = compare(from: NEW, to: PTU)

      assert_equal [only_in_ptu.id], result.appeared
    end

    # --- What a comparison looks at --------------------------------------------

    # Prose changes constantly and says nothing a reader came for. Measured on
    # live 4.9.0 against 4.10.0: 2,171 of the 2,182 changed components differed on
    # `description` alone.
    test "does not compare prose" do
      component = create(:component, :without_build)
      build_for(OLD, component:, name: "Same", description: "before")
      build_for(NEW, component:, name: "Same", description: "after")

      assert_empty compare.changed
      assert_not_includes ::ScData::BuildCompare.diffable_facts(ComponentBuild), :description
    end

    # Two loads of the same export can serialise a shape differently with nothing
    # having changed, so comparing them reports a difference on every re-parse.
    test "does not compare a serialized shape" do
      component = create(:component, :without_build)
      build_for(OLD, component:, name: "Same", type_data: {"a" => 1})
      build_for(NEW, component:, name: "Same", type_data: {"a" => 2})

      assert_empty compare.changed
      assert_not_includes ::ScData::BuildCompare.diffable_facts(ComponentBuild), :type_data
    end

    # `ModelBuild` tuned its own list by hand for the change log; the comparer
    # defers to it rather than deriving a second answer.
    test ".diffable_facts defers to a class that names its own" do
      assert_equal ModelBuild::DIFFABLE_FACTS, ::ScData::BuildCompare.diffable_facts(ModelBuild)
    end

    # --- Which record a build describes -----------------------------------------

    # Derived from the one required `belongs_to`, so a new catalogue needs no
    # registration. The optional ones -- `manufacturer`, and `component` on a
    # hardpoint -- are facts about the record rather than the record itself.
    test ".subject_key finds the record every build class describes" do
      expected = {
        ComponentBuild => "component_id",
        EquipmentBuild => "equipment_id",
        CommodityBuild => "commodity_id",
        ModelBuild => "model_id",
        HardpointBuild => "hardpoint_id"
      }

      expected.each do |build_class, foreign_key|
        assert_equal foreign_key, ::ScData::BuildCompare.subject_key(build_class),
          "#{build_class} should be keyed on #{foreign_key}"
      end
    end

    # Commodities and models only gained build rows in 4.10.0, so a diff against
    # 4.9.0 reported all 232 and all 215 of them as new -- which is a wrong
    # answer rather than a surprising one.
    test "#call reports a catalogue with no rows on one side as not recorded" do
      build_for(NEW)

      result = compare

      assert_not result.recorded?
      assert_empty result.appeared, "the lists stay empty so the flag cannot be ignored into a wrong reading"
      assert_empty result.vanished
    end

    test "#call is recorded when both sides have rows" do
      build_for(OLD)
      build_for(NEW)

      assert_predicate compare, :recorded?
    end

    test "#counts summarises without walking the lists again" do
      build_for(NEW)
      build_for(OLD)

      assert_equal({appeared: 1, vanished: 1, changed: 0}, compare.counts)
    end
  end
end
