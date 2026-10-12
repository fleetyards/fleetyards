# frozen_string_literal: true

# What a dedication plaque says about the company that built the ship.
#
# The short name heads the plaque's crew columns, "Drake Shipwrights" rather
# than "Drake Interplanetary Shipwrights": it is what players call the company,
# and the game files carry none.
#
# The shipyard is where the company builds its ships, phrased the way a plaque
# reads "Commissioned from ...". Lore rarely separates a shipyard from a
# headquarters; where it does not, the headquarters or home world stands in.
# Banu, Grey's Market and the Vanduul have no such place in the lore. Only
# Orison is a place the starmap carries, so only Crusader gets a link.
class SetManufacturerPlaqueDetails < ActiveRecord::Migration[8.1]
  SHORT_NAMES = {
    "ANVL" => "Anvil",
    "RSI" => "RSI",
    "AEGS" => "Aegis",
    "DRAK" => "Drake",
    "MISC" => "MISC",
    "ORIG" => "Origin",
    "TMBL" => "Tumbril",
    "ARGO" => "Argo",
    "MRAI" => "Mirai",
    "CRUS" => "Crusader",
    "GRIN" => "Greycat",
    "CNOU" => "C.O.",
    "ESPR" => "Esperia",
    "KRIG" => "Kruger",
    "XNAA" => "Aopoa",
    "GAMA" => "Gatac",
    "BANU" => "Banu",
    "GREY" => "Grey's",
    "VNCL" => "Vanduul"
  }.freeze

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
    SHORT_NAMES.each do |code, short_name|
      Manufacturer.where(code:, short_name: nil).update_all(short_name:, updated_at: Time.current)
    end

    SHIPYARDS.each do |code, shipyard|
      Manufacturer.where(code:, shipyard: nil).update_all(
        shipyard:,
        shipyard_location_id: LINKED_LOCATIONS[code]&.then { |slug| Location.where(slug:).pick(:id) },
        updated_at: Time.current
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
