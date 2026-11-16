# frozen_string_literal: true

require "test_helper"

class DerivedCargoHoldsTest < ActiveSupport::TestCase
  # `limits` is required by the CargoHold component and present on every hold in
  # the live catalogue, so a fixture without it renders a payload the API says
  # cannot exist — which cable validation now rejects.
  private def hold(name, capacity: 32, size: 2.5, max_container_size: {"size" => 2, "dimensions" => {"x" => 2.5, "y" => 1.25, "z" => 1.25}})
    {
      "name" => name,
      "capacity" => capacity,
      "dimensions" => {"x" => size, "y" => size, "z" => size},
      "max_container_size" => max_container_size,
      "limits" => {
        "min" => {"dimensions" => {"x" => 1.25, "y" => 1.25, "z" => 1.25}, "capacity" => 1},
        "max" => {"dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}, "capacity" => 8}
      }
    }
  end

  private def build_holds(model, holds)
    model.update!(cargo_holds: holds, cargo: 0)
    model.update_cargo_holds_db
    model.cargo_holds_db.reload.order(:position)
  end

  setup do
    @model = create(:model, cargo: 0)
  end

  test "projects each hold in the column into a row, in order" do
    rows = build_holds(@model, [hold("hold_a"), hold("hold_b")])

    assert_equal %w[hold_a hold_b], rows.map(&:name)
    assert_equal [0, 1], rows.map(&:position)
    assert_equal [32, 32], rows.map { |row| row.capacity_scu.to_i }
  end

  test "skips an entry with no dimensions rather than failing on it" do
    rows = build_holds(@model, [hold("hold_a"), {"name" => "broken", "capacity" => 1}])

    assert_equal %w[hold_a], rows.map(&:name)
  end

  # The bug this concern exists for. A build that inserts a hold ahead of a
  # curated one used to shift every curated value onto its neighbour, because
  # the rows were destroyed and the values copied back by array index.
  test "keeps a curated crate limit on its own hold when a hold is inserted ahead of it" do
    grid_max = {"size" => 8, "dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}}
    build_holds(@model, [hold("hold_a", max_container_size: grid_max), hold("hold_b", max_container_size: grid_max)])
    @model.cargo_holds_db.find_by(name: "hold_b").update!(max_loadable_container_size_scu: 2)

    rows = build_holds(@model, [hold("hold_new", max_container_size: grid_max), hold("hold_a", max_container_size: grid_max), hold("hold_b", max_container_size: grid_max)])

    limited = rows.find { |row| row.name == "hold_b" }
    assert_equal 2, limited.max_loadable_container_size_scu
    assert_equal 2, limited.position, "position still tracks the new order"

    assert_nil rows.find { |row| row.name == "hold_new" }.max_loadable_container_size_scu
    assert_nil rows.find { |row| row.name == "hold_a" }.max_loadable_container_size_scu
  end

  test "keeps a curated crate limit when the holds are reordered" do
    grid_max = {"size" => 8, "dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}}
    build_holds(@model, [hold("hold_a", max_container_size: grid_max), hold("hold_b", max_container_size: grid_max)])
    @model.cargo_holds_db.find_by(name: "hold_a").update!(max_loadable_container_size_scu: 2)

    rows = build_holds(@model, [hold("hold_b", max_container_size: grid_max), hold("hold_a", max_container_size: grid_max)])

    assert_equal 2, rows.find { |row| row.name == "hold_a" }.max_loadable_container_size_scu
    assert_nil rows.find { |row| row.name == "hold_b" }.max_loadable_container_size_scu
  end

  # Updated in place rather than rebuilt, so anything hanging off the row -- and
  # the row a curated limit was set on -- survives a reload.
  test "reuses the existing row instead of replacing it" do
    original_id = build_holds(@model, [hold("hold_a")]).first.id

    rows = build_holds(@model, [hold("hold_a", capacity: 64)])

    assert_equal original_id, rows.first.id
    assert_equal 64, rows.first.capacity_scu.to_i
  end

  test "drops a hold the column stopped carrying" do
    build_holds(@model, [hold("hold_a"), hold("hold_b")])

    rows = build_holds(@model, [hold("hold_a")])

    assert_equal %w[hold_a], rows.map(&:name)
  end

  test "leaves no holds behind when the column empties" do
    build_holds(@model, [hold("hold_a")])

    assert_empty build_holds(@model, [])
  end

  # Names are not unique in the export, so the ordinal among holds sharing one
  # is part of the key. Two same-named holds must not collapse into one row.
  test "keeps holds that share a name apart" do
    rows = build_holds(@model, [hold("bay"), hold("bay", capacity: 64)])

    assert_equal 2, rows.size
    assert_equal [32, 64], rows.map { |row| row.capacity_scu.to_i }
  end

  test "keeps holds with no name at all apart" do
    rows = build_holds(@model, [hold(nil), hold(nil, capacity: 64)])

    assert_equal 2, rows.size
    assert_equal [32, 64], rows.map { |row| row.capacity_scu.to_i }
  end

  test "recalculates container capacities for a hold it updated" do
    build_holds(@model, [hold("hold_a", size: 2.5)])

    rows = build_holds(@model, [hold("hold_a", size: 5.0)])

    assert_predicate rows.first.cargo_hold_container_capacities.count, :positive?
  end

  test "keeps a hand-set loadable crate size through a reload, and serves it as the hold's largest" do
    grid_max = {"size" => 8, "dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}}
    build_holds(@model, [hold("hold_a", max_container_size: grid_max)])
    @model.cargo_holds_db.find_by(name: "hold_a").update!(max_loadable_container_size_scu: 2)

    rows = build_holds(@model, [hold("hold_a", capacity: 16, max_container_size: grid_max)])

    assert_equal 2, rows.first.max_loadable_container_size_scu
    assert_equal 8, rows.first.max_container_size_scu
    assert_equal 0, rows.first.cargo_hold_container_capacities.find_by(container_size_scu: 8).max_quantity

    served = @model.reload.cargo_holds_with_placement.first
    assert_equal({"size" => 2, "dimensions" => {"x" => 2.5, "y" => 1.25, "z" => 1.25}}, served["max_container_size"])
    assert_nil served["position"], "a loadable size alone places nothing"
  end

  test "lets a load shrink the grid under a curated limit, which then stops applying" do
    build_holds(@model, [hold("hold_a", max_container_size: {"size" => 8, "dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}})])
    @model.cargo_holds_db.find_by(name: "hold_a").update!(max_loadable_container_size_scu: 4)

    rows = build_holds(@model, [hold("hold_a")])

    assert_equal 4, rows.first.max_loadable_container_size_scu
    assert_equal 2, @model.reload.cargo_holds_with_placement.first.dig("max_container_size", "size")
  end

  # ModelModule carries the same column and used to carry its own copy of this.
  test "works the same for a model module" do
    model_module = create(:model_module)

    model_module.update!(cargo_holds: [hold("module_bay")], cargo: 0)
    model_module.update_cargo_holds_db

    assert_equal %w[module_bay], model_module.cargo_holds_db.reload.map(&:name)
  end

  test "places every hold where the ship-view export measured it" do
    build_holds(@model, [hold("hold_a"), hold("hold_b")])
    @model.update!(hardpoint_transforms: {"ports" => [], "cargo_grids" => [
      {"name" => "hold_a", "position" => [0.0, 1.25, 0.0], "rotation" => [0.0, -Math.sqrt(0.5), 0.0, Math.sqrt(0.5)], "dimensions" => [2.5, 2.5, 2.5]},
      {"name" => "hold_b", "position" => [0.0, 1.25, 5.0], "rotation" => [0.0, 0.0, 0.0, 1.0], "dimensions" => [2.5, 2.5, 2.5]}
    ]})

    hold_a, hold_b = Model.find(@model.id).cargo_holds_with_placement

    assert_equal "model/#{@model.slug}", hold_a["placed_in"]
    assert_equal [0.0, 1.25, 0.0], hold_a["position"]
    assert_equal [0.0, -Math.sqrt(0.5), 0.0, Math.sqrt(0.5)], hold_a["orientation"]
    assert_equal [0.0, 0.0, 0.0, 1.0], hold_b["orientation"]
  end

  test "places no hold when the export places only some of them" do
    build_holds(@model, [hold("hold_a"), hold("hold_b")])
    @model.update!(hardpoint_transforms: {"ports" => [], "cargo_grids" => [
      {"name" => "hold_a", "position" => [0.0, 1.25, 0.0], "rotation" => [0.0, 0.0, 0.0, 1.0], "dimensions" => [2.5, 2.5, 2.5]}
    ]})

    holds = Model.find(@model.id).cargo_holds_with_placement

    assert holds.none? { |hold| hold["placed_in"] || hold["position"] || hold["orientation"] }, holds.inspect
  end

  test "keeps a curated crate limit on a hold the export places" do
    grid_max = {"size" => 8, "dimensions" => {"x" => 2.5, "y" => 2.5, "z" => 2.5}}
    build_holds(@model, [hold("hold_a", max_container_size: grid_max)])
    @model.cargo_holds_db.first.update!(max_loadable_container_size_scu: 2)
    @model.update!(hardpoint_transforms: {"ports" => [], "cargo_grids" => [
      {"name" => "hold_a", "position" => [0.0, 1.25, 0.0], "rotation" => [0.0, 0.0, 0.0, 1.0], "dimensions" => [2.5, 2.5, 2.5]}
    ]})

    hold_a, = Model.find(@model.id).cargo_holds_with_placement

    assert hold_a["placed_in"]
    assert_equal 2, hold_a.dig("max_container_size", "size")
  end
end
