# frozen_string_literal: true

# A parent whose `cargo_holds` YAML column -- written by the sc_data loader out
# of the game files -- is projected into CargoHold rows so a hold can be queried,
# and so it can carry the loadable crate size an admin set by hand.
#
# The geometry is rewritten on every load. `max_loadable_container_size_scu` is
# never written here at all, which is what keeps it on the hold it was set on.
module DerivedCargoHolds
  extend ActiveSupport::Concern

  # The holds, each placed where the hull export says it sits. That export is
  # the only source of placement: a parent it does not place every hold of
  # comes back with none placed, since half a layout would overlap the rest.
  def cargo_holds_with_offsets
    holds = projected_cargo_holds

    measured = measured_cargo_placements
    placed = holds.any? && holds.all? { |hold| measured.key?(hold["name"]) }

    # Selected in Ruby rather than with `where`, which would issue a query per
    # record and so ignore a preloaded association -- 50 queries for a page of
    # 50 ships. There are a handful of holds per parent, so the filtering itself
    # costs nothing either way.
    limits = cargo_holds_db
      .select(&:max_loadable_container_size_scu)
      .index_by(&:position)

    holds.each_with_index.map do |hold_data, index|
      extra = placed ? measured[hold_data["name"]].compact.merge("placed_in" => cargo_placement_frame) : {}

      loadable = limits[index] && loadable_container_size(limits[index])
      extra["max_container_size"] = loadable if loadable

      hold_data.merge(extra)
    end
  end

  # Holds are matched to their existing row and updated in place. They used to be
  # destroyed and rebuilt, with the placement columns copied back onto whatever
  # row landed at the same array index -- so adding, dropping or reordering a
  # hold in the game files moved a curated value onto a different hold, quietly.
  def update_cargo_holds_db
    holds = projected_cargo_holds
    keys = cargo_hold_keys(holds.map { |hold| hold["name"] })

    existing = cargo_holds_db.order(:position).to_a
    by_key = cargo_hold_keys(existing.map(&:name)).zip(existing).to_h

    kept = holds.each_with_index.map do |hold_data, index|
      record = by_key[keys[index]] || cargo_holds_db.new

      record.assign_attributes(derived_cargo_hold_attributes(hold_data).merge(position: index))
      record.save!

      record.calculate_container_capacities!

      record.id
    end

    # `where.not(id: [])` is `1=1`, which is wanted here: a parent the export
    # stopped giving holds should be left with none.
    cargo_holds_db.where.not(id: kept).destroy_all
  end

  # Matched on the name the hardpoint carries, not on `position` -- position is
  # only the index in the array the loader wrote, and it moves with the build.
  #
  # A hold the loader wrote without dimensions is not projected into a row, so
  # it has no position a curated value could be matched to. Both readers have to skip
  # the same ones: `cargo_holds_with_offsets` pairs holds to rows by array
  # index, and filtering in one place but not the other shifts every value
  # past a malformed hold onto its neighbour — the bug this concern exists for,
  # arrived at from the other side.
  private def projected_cargo_holds
    (cargo_holds || []).reject { |hold| hold.blank? || hold["dimensions"].blank? }
  end

  # Names are not quite unique in practice (a couple of models repeat one, and a
  # few holds carry none at all), so the ordinal among holds sharing a name is
  # part of the key. An unnamed hold falls back to its ordinal among the unnamed,
  # which is no worse than what it had before.
  private def cargo_hold_keys(names)
    seen = Hash.new(0)

    names.map do |raw_name|
      name = raw_name.presence
      key = [name, seen[name]]

      seen[name] += 1

      key
    end
  end

  # The holds' placements a parent has measured; none by default.
  def measured_cargo_placements
    {}
  end

  # Names the export the holds were placed from: holds placed from different
  # exports -- a ship and a module fitted to it -- are each in their own frame.
  def cargo_placement_frame
    "#{model_name.element}/#{slug}"
  end

  # Only a limit below what the grid itself takes changes anything.
  private def loadable_container_size(db_record)
    size = db_record.max_loadable_container_size_scu
    return if size.blank? || size >= db_record.max_container_size_scu

    container = ScData::CargoFinder::CARGO_CONTAINER_DIMENSIONS.find { |entry| entry[:size] == size }
    return if container.blank?

    {"size" => size, "dimensions" => container[:dimensions].stringify_keys}
  end

  private def derived_cargo_hold_attributes(hold_data)
    {
      name: hold_data["name"],
      dimension_x: hold_data["dimensions"]["x"],
      dimension_y: hold_data["dimensions"]["y"],
      dimension_z: hold_data["dimensions"]["z"],
      capacity_scu: hold_data["capacity"],
      max_container_size_scu: hold_data.dig("max_container_size", "size"),
      max_container_dimension_x: hold_data.dig("max_container_size", "dimensions", "x"),
      max_container_dimension_y: hold_data.dig("max_container_size", "dimensions", "y"),
      max_container_dimension_z: hold_data.dig("max_container_size", "dimensions", "z"),
      min_container_size_scu: hold_data.dig("limits", "min", "capacity"),
      min_container_dimension_x: hold_data.dig("limits", "min", "dimensions", "x"),
      min_container_dimension_y: hold_data.dig("limits", "min", "dimensions", "y"),
      min_container_dimension_z: hold_data.dig("limits", "min", "dimensions", "z")
    }
  end
end
