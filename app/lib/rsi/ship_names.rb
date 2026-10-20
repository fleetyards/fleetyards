# frozen_string_literal: true

module Rsi
  # The names RSI's pledge pages give ships whose names differ from ours, mapped
  # to the name or RSI name of our model.
  module ShipNames
    MAPPING = {
      "A.T.L.S" => "ATLS",
      "A.T.L.S." => "ATLS",
      "A.T.L.S Geo" => "ATLS Geo",
      "A.T.L.S. Geo" => "ATLS Geo",
      "GreyCat Estate Geotack Planetary Beacon" => "Geotack Planetary Beacon",
      "GreyCat Estate Geotack-X Planetary Beacon" => "Geotack-X Planetary Beacon",
      "X1 Base" => "X1",
      "315p Explorer" => "315p",
      "325a Fighter" => "325a",
      "350r Racer" => "350r",
      "Ursa Rover" => "Ursa",
      "Ursa Rover Fortuna" => "Ursa Fortuna",
      "600i" => "600i Explorer",
      "600i Exploration Module" => "600i Explorer",
      "600i Touring Module" => "600i Touring",
      "Mercury Star Runner" => "Mercury",
      "Captured Vanduul Scythe" => "Scythe",
      "Caterpillar 2949 Best in Show" => "Caterpillar Best In Show Edition 2949",
      "Cutlass 2949 Best In Show" => "Cutlass Black Best In Show Edition 2949",
      "Dragonfly" => "Dragonfly Black",
      "F8C Lightning Civilian" => "F8C Lightning",
      "Hammerhead 2949 Best in Show" => "Hammerhead Best In Show Edition 2949",
      "Hercules Starlifter A2" => "A2 Hercules",
      "Hercules Starlifter C2" => "C2 Hercules",
      "Hercules Starlifter M2" => "M2 Hercules",
      "Genesis Starliner" => "Genesis",
      "Hornet F7C Mk I" => "F7C Hornet Mk I",
      "F7A Hornet Mk 1" => "F7A Hornet Mk I",
      "F7C-M Hornet Heartseeker Mk I" => "F7C-M Super Hornet Heartseeker Mk I",
      "Hornet F7C-M Heartseeker Mk I" => "F7C-M Super Hornet Heartseeker Mk I",
      "Idris-M Frigate" => "Idris-M",
      "Idris-P Frigate" => "Idris-P",
      "Idris-K Frigate" => "Idris-P",
      "Greycat PTV" => "PTV",
      "GRIN ROC DS" => "ROC DS",
      "Greycat Industrial - ROC" => "ROC",
      "Gatac Railen" => "Railen",
      "Carrack Expedition with Pisces Expedition" => "Carrack Expedition",
      "Carrack with Pisces Expedition" => "Carrack",
      "Mustang Omega : AMD Edition" => "Mustang Omega",
      "Nova Tank" => "Nova",
      "Pisces" => "C8 Pisces",
      "Pisces - Expedition" => "C8X Pisces Expedition",
      "Reclaimer 2949 Best in Show" => "Reclaimer Best In Show Edition 2949",
      "Reliant Kore - Mini Hauler" => "Reliant Kore",
      "Reliant Mako - News Van" => "Reliant Mako",
      "Reliant Sen - Researcher" => "Reliant Sen",
      "Reliant Tana - Skirmisher" => "Reliant Tana",
      "Rover" => "G12a Rover",
      "Retaliator Base" => "Retaliator",
      "Retaliator Bomber" => "Retaliator",
      "Crusader A1 Spirit" => "A1 Spirit",
      "Crusader C1 Spirit" => "C1 Spirit",
      "Crusader E1 Spirit" => "E1 Spirit",
      "Gladius Dunlevy" => "Dunlevy",
      "Constellation Phoenix" => "Constellation Mk IV Phoenix",
      "Constellation Mk IV Phoenix Emerald" => "Constellation Phoenix Emerald",
      "Vanduul Blade" => "Blade",
      "X1 - FORCE" => "X1 Force",
      "X1 - VELOCITY" => "X1 Velocity",
      "Ballista Dunestalker" => "Ballista",
      "Ballista Snowblind" => "Ballista",
      "Mustang Alpha Vindicator" => "Mustang Alpha"
    }.freeze

    # Every name an RSI pledge page may give a ship we call one of `names`,
    # downcased, the names themselves included.
    def self.aliases(names)
      names = names.filter_map { |name| name.presence&.strip&.downcase }

      (names + MAPPING.filter_map { |rsi_name, name| rsi_name.downcase if names.include?(name.downcase) }).uniq
    end
  end
end
