# frozen_string_literal: true

require "test_helper"

module ScData
  class BuildDiffTest < ActiveSupport::TestCase
    OLD = ::ScData::Source.new(environment: "live", version: "1.0.0-live.1")
    NEW = ::ScData::Source.new(environment: "ptu", version: "1.0.1-ptu.2")

    private def diff(catalogue)
      ::ScData::BuildDiff.new(catalogue, from: OLD, to: NEW).call
    end

    private def build_for(factory, source, **attributes)
      create(factory, environment: source.environment, version: source.version, **attributes)
    end

    private def component_pair(old, new)
      component = create(:component, :without_build)
      build_for(:component_build, OLD, component:, **old)
      build_for(:component_build, NEW, component:, **new)
      component
    end

    test "#call carries both values of a changed fact" do
      component_pair({name: "Bulwark", size: "1"}, {name: "Bulwark", size: "2"})

      entry = diff("components").entries.sole

      assert_equal ["Bulwark", "changed"], [entry.name, entry.kind]
      assert_equal [["size", "1", "2"]], entry.fields.map { |f| [f.field, f.from, f.to] }
    end

    test "#call reads a component's metrics out of its type data" do
      component_pair({name: "Gun", type_data: {"damage" => 10}}, {name: "Gun", type_data: {"damage" => 12}})

      field = diff("components").entries.sole.fields.sole

      assert_equal ["type_data.damage", 10, 12], [field.field, field.from, field.to]
    end

    test "#call leaves out records the game never named and hidden ones" do
      component_pair({name: nil, size: "1"}, {name: nil, size: "2"})
      component_pair({name: "Door", size: "1", hidden: true}, {name: "Door", size: "2", hidden: true})

      assert_empty diff("components").entries
    end

    test "#call names a manufacturer rather than its id" do
      before = create(:manufacturer, name: "Alpha")
      after = create(:manufacturer, name: "Beta")
      equipment = create(:equipment)
      build_for(:equipment_build, OLD, equipment:, name: "Helmet", manufacturer: before)
      build_for(:equipment_build, NEW, equipment:, name: "Helmet", manufacturer: after)

      field = diff("equipment").entries.sole.fields.find { |f| f.field == "manufacturer" }

      assert_equal %w[Alpha Beta], [field.from, field.to]
    end

    test "#call names a ship, whose build rows carry no name" do
      model = create(:model, name: "Javelin")
      build_for(:model_build, OLD, model:, crew: 1)
      build_for(:model_build, NEW, model:, crew: 65)

      entry = diff("models").entries.sole

      assert_equal "Javelin", entry.name
      assert_equal [["crew", 1, 65]], entry.fields.map { |f| [f.field, f.from, f.to] }
    end

    test "#call compares what a module carries" do
      model_module = create(:model_module, name: "Cargo Module")
      build_for(:model_module_build, OLD, model_module:, cargo_holds: [{"capacity" => 8}])
      build_for(:model_module_build, NEW, model_module:, cargo_holds: [{"capacity" => 16}])

      field = diff("modules").entries.sole.fields.sole

      assert_equal ["cargo", 8.0, 16.0], [field.field, field.from, field.to]
    end

    test "#call counts a module's medical beds" do
      model_module = create(:model_module, name: "Medical Module")
      beds = ->(count) { {"tiers" => [{"tier" => 1, "beds" => count}], "respawn_beds" => count} }
      build_for(:model_module_build, OLD, model_module:, medical_beds: beds.call(1))
      build_for(:model_module_build, NEW, model_module:, medical_beds: beds.call(3))

      field = diff("modules").entries.sole.fields.sole

      assert_equal ["medical_beds", 1, 3], [field.field, field.from, field.to]
    end

    test "#call groups a ship's slots under the ship and names what they hold" do
      model = create(:model, name: "Ballista")
      [OLD, NEW].each { |source| build_for(:model_build, source, model:) }
      radar = component_pair({name: "Old Radar"}, {name: "Old Radar"})
      newer = component_pair({name: "New Radar"}, {name: "New Radar"})
      hardpoint = create(:hardpoint, parent: model, sc_name: "hardpoint_radar_front")
      HardpointBuild.where(hardpoint:).delete_all
      build_for(:hardpoint_build, OLD, hardpoint:, component: radar)
      build_for(:hardpoint_build, NEW, hardpoint:, component: newer, category: :radar)

      entry = diff("loadouts").entries.sole

      assert_equal "Ballista", entry.name
      assert_equal HardpointBuild.find_by(hardpoint:, version: NEW.version).category, entry.fields.sole.category
      assert_equal [["hardpoint_radar_front", "Old Radar", "New Radar"]], entry.fields.map { |f| [f.field, f.from, f.to] }
    end

    test "#call reads a part only one build names as no change to the loadout" do
      model = create(:model)
      [OLD, NEW].each { |source| build_for(:model_build, source, model:) }
      part = component_pair({name: nil}, {name: "Hull Armor"})
      hardpoint = create(:hardpoint, parent: model, sc_name: "hardpoint_armor")
      HardpointBuild.where(hardpoint:).delete_all
      [OLD, NEW].each { |source| build_for(:hardpoint_build, source, hardpoint:, component: part) }

      assert_empty diff("loadouts").entries
    end

    test "#call says nothing of a slot whose part has no name to show" do
      model = create(:model)
      [OLD, NEW].each { |source| build_for(:model_build, source, model:) }
      unnamed = component_pair({name: nil}, {name: nil})
      named = component_pair({name: "Radar"}, {name: "Radar"})
      hardpoint = create(:hardpoint, parent: model, sc_name: "hardpoint_radar")
      HardpointBuild.where(hardpoint:).delete_all
      build_for(:hardpoint_build, OLD, hardpoint:, component: unnamed)
      build_for(:hardpoint_build, NEW, hardpoint:, component: named)

      assert_empty diff("loadouts").entries
    end

    test "#call reads a record the newer build names as changed, not added" do
      component_pair({name: nil}, {name: "Hull Armor"})

      entry = diff("components").entries.sole

      assert_equal %w[changed name], [entry.kind, entry.fields.sole.field]
    end

    test "#call reads a record the newer build hides as removed" do
      component_pair({name: "Gun", hidden: false}, {name: "Gun", hidden: true})

      assert_equal "removed", diff("components").entries.sole.kind
    end

    test "#call reads a renamed slot holding the same part as no change" do
      model = create(:model)
      [OLD, NEW].each { |source| build_for(:model_build, source, model:) }
      part = component_pair({name: "ComfortAir"}, {name: "ComfortAir"})
      [["hardpoint_lifesupport", OLD], ["hardpoint_life_support", NEW]].each do |sc_name, source|
        hardpoint = create(:hardpoint, parent: model, sc_name:)
        HardpointBuild.where(hardpoint:).delete_all
        build_for(:hardpoint_build, source, hardpoint:, component: part)
      end

      assert_empty diff("loadouts").entries
    end

    test "#call says a catalogue one side never recorded is not recorded" do
      build_for(:component_build, NEW, component: create(:component, :without_build), name: "New")

      result = diff("components")

      assert_not result.recorded
      assert_empty result.entries
    end

    test "#call leaves out a fact one build states for no record" do
      5.times { |index| component_pair({name: "Gun #{index}", size: "1"}, {name: "Gun #{index}", size: "1", type_data: {"damage" => index}}) }

      result = diff("components")

      assert_empty result.entries
      assert_equal [["type_data.damage", 5]], result.unrecorded
    end

    test "#call keeps a fact too few records gained to tell" do
      component_pair({name: "Gun", size: "1"}, {name: "Gun", size: "1", type_data: {"damage" => 1}})

      result = diff("components")

      assert_equal 1, result.entries.size
      assert_empty result.unrecorded
    end

    test "#call keeps a fact both builds state when all its values change" do
      5.times { |index| component_pair({name: "Gun #{index}", size: "1"}, {name: "Gun #{index}", size: "2"}) }

      assert_equal 5, diff("components").entries.size
    end

    test "#call counts each kind and each fact" do
      component_pair({name: "A", size: "1"}, {name: "A", size: "2"})
      build_for(:component_build, NEW, component: create(:component, :without_build), name: "B")

      result = diff("components")

      assert_equal({"added" => 1, "removed" => 0, "changed" => 1}, result.counts)
      assert_equal [["size", 1]], result.field_counts
    end

    ScData::BuildDiff::CATALOGUES.each_key do |catalogue|
      test "#call answers for #{catalogue} with nothing recorded" do
        assert_not diff(catalogue).recorded
      end
    end
  end
end
