# frozen_string_literal: true

# The focus stored before the keys was often the ship matrix's wording from
# years back: RSI rewords ships without moving `time_modified`, and the loader
# only copied the wording on a run where it did. So "Exploration" became
# `expedition` where the matrix now says "Pathfinder", and the Aurora Mk II
# lost the "Starter" the matrix has since added. Where the matrix's current
# wording gives a key a ship is missing, its keys take over, except on a ship
# an admin has picked keys for.
#
# `recon` leaves the vocabulary: the matrix never words a ship that way, and
# the slots that asked for it ask for a pathfinder instead.
class FollowRsiFocusWording < ActiveRecord::Migration[8.1]
  # Decided one by one when the keys were introduced.
  KEEP = %w[
    drak-kraken drak-kraken-privateer banu-merchantman
    anvl-f7c-s-hornet-ghost-mk-i anvl-f7c-s-hornet-ghost-mk-ii aegs-sabre mrai-razor-ex
  ].freeze

  # Where the matrix's wording is wrong for the ship: the Sentinel carries the
  # Harbinger's "Heavy Fighter / Bomber", and the Cyclone and the HoverQuad are
  # no passenger vehicles.
  OWN = {
    "aegs-vanguard-sentinel" => %w[interdiction heavy_fighter],
    "tmbl-cyclone" => %w[expedition],
    "cnou-hoverquad" => %w[racing]
  }.freeze

  def up
    edited = select_values(<<~SQL.squish)
      SELECT DISTINCT item_id FROM versions
      WHERE item_type = 'Model' AND whodunnit IS NOT NULL AND (object_changes::jsonb ? 'foci')
    SQL

    select_rows("SELECT id, slug, rsi_focus, array_to_json(foci), stealth FROM models").each do |id, slug, rsi_focus, foci, stealthy|
      next if KEEP.include?(slug) || edited.include?(id)

      foci = JSON.parse(foci)
      rsi = ::Models::FocusMapping.call(rsi_focus)
      keys = OWN.fetch(slug) { (rsi.foci.any? && (rsi.foci - foci).any?) ? rsi.foci : without_recon(foci) }
      keys = ::Model.normalize_value_for(:foci, keys)
      stealth = rsi.stealth && !stealthy && !OWN.key?(slug)

      next if keys == foci && !stealth

      execute <<~SQL.squish
        UPDATE models
        SET foci = #{array(keys)}, focus = #{quote(focus(keys))}#{", stealth = TRUE" if stealth}, updated_at = NOW()
        WHERE id = #{quote(id)}
      SQL
    end

    %w[fleet_event_ships mission_ships].each do |table|
      select_rows("SELECT id, array_to_json(foci) FROM #{table} WHERE 'recon' = ANY(foci)").each do |id, foci|
        keys = ::Model.ordered_foci(without_recon(JSON.parse(foci)))

        execute "UPDATE #{table} SET foci = #{array(keys)}, focus = #{quote(focus(keys))} WHERE id = #{quote(id)}"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private def without_recon(foci)
    foci.map { |key| (key == "recon") ? "pathfinder" : key }
  end

  # The string the keys replaced, still served beside them, in the words
  # `FociList` keeps it in.
  private def focus(keys)
    I18n.with_locale(:en) { ::Model.focus_labels(keys).join(" / ") }.presence
  end

  private def array(keys)
    "ARRAY[#{keys.map { |key| quote(key) }.join(", ")}]::varchar[]"
  end

  private def quote(value)
    connection.quote(value)
  end
end
