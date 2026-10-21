# frozen_string_literal: true

# Each ship's focus, and each crew slot's, in the catalogue's keys.
#
# The stored focus is the one admins curated, so it leads. Where it says
# nothing more than "Combat" or "Industrial" -- mostly on ground vehicles -- the
# ship matrix's wording is more specific (a Nova is a tank, a Centurion
# anti-air) and its keys are added. A ship is stealthy where either source says
# so.
class MapModelFocusToFoci < ActiveRecord::Migration[8.1]
  GENERIC = [%w[assault], []].freeze

  # Ships whose keys were decided one by one rather than read off a source.
  SHIPS = {
    "drak-kraken" => {foci: %w[carrier freight]},
    "drak-kraken-privateer" => {foci: %w[carrier merchant]},
    "banu-merchantman" => {foci: %w[freight merchant]},
    "anvl-f7c-s-hornet-ghost-mk-i" => {foci: %w[medium_fighter], stealth: true},
    "anvl-f7c-s-hornet-ghost-mk-ii" => {foci: %w[medium_fighter], stealth: true},
    "aegs-sabre" => {foci: %w[medium_fighter], stealth: true},
    "mrai-razor-ex" => {foci: %w[light_fighter racing], stealth: true}
  }.freeze

  def up
    select_rows("SELECT id, slug, focus, rsi_focus FROM models").each do |id, slug, focus, rsi_focus|
      stored = ::Models::FocusMapping.call(focus)
      rsi = ::Models::FocusMapping.call(rsi_focus)

      foci = stored.foci
      foci += rsi.foci if GENERIC.include?(foci)
      stealth = stored.stealth || rsi.stealth

      decided = SHIPS.fetch(slug, {})
      foci = decided.fetch(:foci, foci)
      stealth = decided.fetch(:stealth, stealth)

      execute <<~SQL.squish
        UPDATE models
        SET foci = #{array(foci)}, stealth = #{quote(stealth)}, updated_at = NOW()
        WHERE id = #{quote(id)}
      SQL
    end

    %w[fleet_event_ships mission_ships].each do |table|
      select_rows("SELECT id, focus FROM #{table} WHERE focus IS NOT NULL").each do |id, focus|
        foci = ::Models::FocusMapping.call(focus).foci

        execute "UPDATE #{table} SET foci = #{array(foci, umbrellas: false)} WHERE id = #{quote(id)}"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private def array(foci, umbrellas: true)
    foci = umbrellas ? ::Model.normalize_value_for(:foci, foci) : ::Model.ordered_foci(foci)

    "ARRAY[#{foci.map { |key| quote(key) }.join(", ")}]::varchar[]"
  end

  private def quote(value)
    connection.quote(value)
  end
end
