# frozen_string_literal: true

require "test_helper"

class DerivedCargoHoldsTest < ActiveSupport::TestCase
  # `limits` is required by the CargoHold component and present on every hold in
  # the live catalogue, so a fixture without it renders a payload the API says
  # cannot exist — which cable validation now rejects.
  private def hold(name, capacity: 32, size: 2.5)
    {
      "name" => name,
      "capacity" => capacity,
      "dimensions" => {"x" => size, "y" => size, "z" => size},
      "max_container_size" => {"size" => 2, "dimensions" => {"x" => 2.5, "y" => 1.25, "z" => 1.25}},
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
  # curated one used to shift every offset onto its neighbour, because the rows
  # were destroyed and the offsets copied back by array index.
  test "keeps a curated offset on its own hold when a hold is inserted ahead of it" do
    build_holds(@model, [hold("hold_a"), hold("hold_b")])
    @model.cargo_holds_db.find_by(name: "hold_b").update!(offset_x: 5, offset_y: 6, offset_z: 7, rotation: 90)

    rows = build_holds(@model, [hold("hold_new"), hold("hold_a"), hold("hold_b")])

    placed = rows.find { |row| row.name == "hold_b" }
    assert_equal [5, 6, 7], [placed.offset_x.to_i, placed.offset_y.to_i, placed.offset_z.to_i]
    assert_equal 90, placed.rotation
    assert_equal 2, placed.position, "position still tracks the new order"

    assert_nil rows.find { |row| row.name == "hold_new" }.offset_x
    assert_nil rows.find { |row| row.name == "hold_a" }.offset_x
  end

  test "keeps a curated offset when the holds are reordered" do
    build_holds(@model, [hold("hold_a"), hold("hold_b")])
    @model.cargo_holds_db.find_by(name: "hold_a").update!(offset_x: 3)

    rows = build_holds(@model, [hold("hold_b"), hold("hold_a")])

    assert_equal 3, rows.find { |row| row.name == "hold_a" }.offset_x.to_i
    assert_nil rows.find { |row| row.name == "hold_b" }.offset_x
  end

  # Updated in place rather than rebuilt, so anything hanging off the row -- and
  # the row a curated offset was set on -- survives a reload.
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

  # ModelModule carries the same column and used to carry its own copy of this.
  test "works the same for a model module" do
    model_module = create(:model_module)

    model_module.update!(cargo_holds: [hold("module_bay")], cargo: 0)
    model_module.update_cargo_holds_db

    assert_equal %w[module_bay], model_module.cargo_holds_db.reload.map(&:name)
  end
end
