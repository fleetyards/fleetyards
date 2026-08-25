# frozen_string_literal: true

# A parent whose `cargo_holds` YAML column -- written by the sc_data loader out
# of the game files -- is projected into CargoHold rows so a hold can be queried,
# and so it can carry placement an admin set by hand.
#
# The geometry is rewritten on every load. The placement columns
# (`offset_x/y/z`, `rotation`) are never written here at all, which is what keeps
# a curated offset on the hold it was set on.
module DerivedCargoHolds
  extend ActiveSupport::Concern

  def cargo_holds_with_offsets
    holds = projected_cargo_holds

    db_records = cargo_holds_db.where.not(offset_x: nil)
      .or(cargo_holds_db.where.not(offset_y: nil))
      .or(cargo_holds_db.where.not(offset_z: nil))
      .or(cargo_holds_db.where.not(rotation: nil))
      .index_by(&:position)

    return holds if db_records.empty?

    holds.each_with_index.map do |hold_data, index|
      db_record = db_records[index]

      next hold_data if db_record.blank?

      extra = {
        "offset" => {
          "x" => db_record.offset_x&.to_f || 0.0,
          "y" => db_record.offset_y&.to_f || 0.0,
          "z" => db_record.offset_z&.to_f || 0.0
        }
      }
      extra["rotation"] = db_record.rotation if db_record.rotation.present?

      hold_data.merge(extra)
    end
  end

  # Holds are matched to their existing row and updated in place. They used to be
  # destroyed and rebuilt, with the placement columns copied back onto whatever
  # row landed at the same array index -- so adding, dropping or reordering a
  # hold in the game files moved a curated offset onto a different hold, quietly.
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
  # it has no position an offset could be matched to. Both readers have to skip
  # the same ones: `cargo_holds_with_offsets` pairs holds to rows by array
  # index, and filtering in one place but not the other shifts every offset
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
