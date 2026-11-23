# frozen_string_literal: true

# Store, hangar and game files each spelt some paints their own way -- "Best in
# Show 2950" and "2950 Best in Show", "Heron Black" and "Black Heron", the
# Invictus paints with and without their year -- and each spelling became a
# paint of its own on the same ship. Merges them under the name the hangar uses
# now, and renames the ones with only an old spelling.
class MergeDifferentlySpeltPaints < ActiveRecord::Migration[8.1]
  # Relinking rewrites every paint pledge's links, and a hangar sync writing the
  # same rows would wait on all of them until a wrapping transaction committed.
  disable_ddl_transaction!

  RENAMES = {
    "Caterpillar Best In Show Edition 2949" => "2949 Best in Show",
    "Cutlass Black Best In Show Edition 2949" => "2949 Best in Show",
    "Hammerhead Best In Show Edition 2949" => "2949 Best in Show",
    "Reclaimer Best In Show Edition 2949" => "2949 Best in Show",
    "Invictus Blue & Gold" => "Invictus Blue and Gold",
    "2950 Invictus Blue and Gold" => "Invictus Blue and Gold",
    "2950 Invictus Black" => "Black",
    "2950 Invictus Light Grey" => "Light Grey",
    "2950 Invictus Sage" => "Sage",
    "2950 Invictus Storm Surge" => "Storm Surge",
    "2950 Invictus Green and Gold" => "Green and Gold",
    "2950 Invictus Light and Dark Grey" => "Light and Dark Grey",
    "2950 Invictus Dark Green v" => "Dark Green",
    "2951 Auspicious Red" => "Auspicious Red Ram",
    "2952 Auspicious Red" => "Auspicious Red Monkey",
    "2953 Auspicious Red" => "Auspicious Red Rooster",
    "2953 Auspicious Red Rooster" => "Auspicious Red Rooster",
    "2956 Auspicious Red Rat" => "Auspicious Red Rat",
    "Caterpillar Pirate Edition" => "Pirate Edition",
    "Mole Carbon Edition" => "Carbon",
    "Mole Talus Edition" => "Talus",
    "Constellation Phoenix Emerald" => "Emerald",
    "Black Heron" => "Heron Black",
    "Orange Heron" => "Heron Orange",
    "White Heron" => "Heron White",
    "Skullcusher" => "Skullcrusher",
    "Hadinite" => "Hadanite",
    "Badlands" => "Badland",
    "Bushwhacker" => "Bushwacker",
    "Ch.iiing" => "Ch.iing",
    "Xua'cha" => "Xuā’cha"
  }.freeze

  # Either order of the year and either case of "In"; all become "2952 Best in
  # Show".
  BEST_IN_SHOW = /\A(?:best in show (\d{4})(?: \(red alert\))?|(\d{4}) best in show)\z/i
  BEST_IN_SHOW_SQL = '^(best in show [0-9]{4}( \(red alert\))?|[0-9]{4} best in show)$'

  def up
    vehicle_ids = []

    misspelt_paints.group_by { |paint| [paint.model_id, canonical(paint.name)] }
      .each do |(_model_id, name), paints|
        next if paints.all? { |paint| paint.name == name }

        kept, *duplicates = paints.sort_by { |paint| keep_order(paint) }
        duplicates.each { |duplicate| vehicle_ids.concat(ModelPaintMerger.new(kept, duplicate).run) }
        kept.update!(name:, updated_at: Time.current)
        vehicle_ids.concat(kept.vehicle_ids)
      end

    refresh_vehicles(vehicle_ids.uniq)

    # A pledge resolves to a paint by its exact name, so it may now reach a paint
    # it could not before.
    HangarPledgeItems::PaintLinker.new.link_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private def canonical(name)
    best_in_show = BEST_IN_SHOW.match(name)
    return "#{best_in_show[1] || best_in_show[2]} Best in Show" if best_in_show

    RENAMES.fetch(name, name)
  end

  private def misspelt_paints
    ModelPaint.where(name: RENAMES.keys + RENAMES.values)
      .or(ModelPaint.where("name ~* ?", BEST_IN_SHOW_SQL))
      .to_a
  end

  # The store's own record first, or the store import makes it again; then a
  # paint in the catalogue over a hidden one, and the one most ships carry.
  private def keep_order(paint)
    [paint.rsi_id.present? ? 0 : 1, paint.hidden ? 1 : 0, -paint.vehicle_paints.count, paint.created_at]
  end

  private def refresh_vehicles(vehicle_ids)
    Vehicle.where(id: vehicle_ids).update_all(updated_at: Time.current)
    Vehicle.schedule_fleet_vehicle_updates(vehicle_ids)
  end
end
