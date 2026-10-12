# frozen_string_literal: true

# Where each manufacturer builds its ships, phrased the way a dedication plaque
# reads "Commissioned from ...". Lore rarely separates a shipyard from a
# headquarters; where it does not, the headquarters or home world stands in.
# Banu, Grey's Market and the Vanduul have no such place in the lore.
#
# Only Orison is a place the starmap carries, so only Crusader gets a link.
class SetManufacturerShipyards < ActiveRecord::Migration[8.1]
  SHIPYARDS = {
    "ANVL" => "MacArthur Shipyards, MacArthur (Kilian V)",
    "RSI" => "London Ship Yards, Earth (Sol III)",
    "AEGS" => "Jata, Cestulus (Davien)",
    "DRAK" => "Borea (Magnus II)",
    "MISC" => "Fujin City, Saisei (Centauri)",
    "ORIG" => "New Austin, Terra (Terra III)",
    "TMBL" => "Saisei (Centauri)",
    "ARGO" => "Mars (Sol IV)",
    "MRAI" => "Saisei (Centauri)",
    "CRUS" => "Orison, Crusader (Stanton II)",
    "GRIN" => "Mars (Sol IV)",
    "CNOU" => "Stalford, Rytif (Bremen)",
    "ESPR" => "Kutaram, Terra (Terra III)",
    "KRIG" => "Sherman, Cascom (Castra II)",
    "XNAA" => "Ka'ua (Hyoton)",
    "GAMA" => "Tethle'a (Hyoton)"
  }.freeze

  LINKED_LOCATIONS = {"CRUS" => "orison"}.freeze

  def up
    SHIPYARDS.each do |code, shipyard|
      Manufacturer.where(code:, shipyard: nil).update_all(
        shipyard:,
        shipyard_location_id: Location.where(slug: LINKED_LOCATIONS[code]).pick(:id),
        updated_at: Time.current
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
