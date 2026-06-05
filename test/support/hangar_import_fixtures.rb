# frozen_string_literal: true

module HangarImportFixtures
  IMPORTED_SHIPS = [
    "100i", "125a", "135c", "300i", "315p", "325a", "350r",
    "600i Executive-Edition", "600i Explorer", "600i Touring", "85X", "890 Jump",
    "A2 Hercules", "Apollo Medivac", "Apollo Triage", "Ares Inferno", "Ares Ion", "Arrow",
    "Aurora CL", "Aurora ES", "Aurora LN", "Aurora LX", "Aurora MR",
    "Avenger Stalker", "Avenger Titan", "Avenger Titan Renegade", "Avenger Warlock",
    "Ballista", "Ballista Dunestalker", "Ballista Snowblind", "Blade", "Buccaneer",
    "C2 Hercules", "C8 Pisces", "C8X Pisces Expedition", "Carrack", "Carrack Expedition",
    "Caterpillar", "Caterpillar", "Caterpillar Pirate Edition",
    "Constellation Andromeda", "Constellation Aquila", "Constellation Phoenix",
    "Constellation Phoenix Emerald", "Constellation Taurus",
    "Corsair", "Crucible", "Cutlass Black", "Cutlass Black", "Cutlass Blue", "Cutlass Red",
    "Cyclone", "Cyclone AA", "Cyclone RC", "Cyclone RN", "Cyclone TR",
    "Defender", "Dragonfly Black", "Dragonfly Starkitten Edition", "Dragonfly Yellowjacket",
    "Eclipse", "Endeavor",
    "F7A Hornet Mk I", "F7C Hornet Mk I", "F7C Hornet Wildfire Mk I",
    "F7C-M Super Hornet Mk I", "F7C-M Super Hornet Mk I", "F7C-R Hornet Tracker Mk I",
    "F7C-S Hornet Ghost Mk I", "F8C Lightning", "F8C Lightning Executive Edition",
    "Freelancer", "Freelancer DUR", "Freelancer MAX", "Freelancer MIS",
    "Genesis", "Gladiator", "Gladius", "Gladius Valiant", "Glaive",
    "Hammerhead", "Hammerhead", "Hawk", "Herald",
    "Hull A", "Hull B", "Hull C", "Hull D", "Hull E", "Hurricane",
    "Idris-M", "Idris-P", "Idris-P", "Javelin", "Khartu-Al", "Kraken", "Kraken Privateer",
    "M2 Hercules", "M50", "MOLE", "MPUV Cargo", "MPUV Personnel",
    "Mantis", "Merchantman", "Mercury", "Mole Carbon Edition", "Mole Talus Edition",
    "Mustang Alpha", "Mustang Alpha Vindicator", "Mustang Beta", "Mustang Delta",
    "Mustang Gamma", "Mustang Omega",
    "Nautilus", "Nautilus Solstice Edition", "Nova", "Nox", "Nox Kue", "Orion",
    "P-52 Merlin", "P-72 Archimedes", "P-72 Archimedes Emerald", "PTV", "Pioneer",
    "Pirate Gladius", "Polaris", "Prospector", "Prowler",
    "Ranger CV", "Ranger RC", "Ranger TR", "Razor", "Razor EX", "Razor LX",
    "Reclaimer", "Reclaimer", "Redeemer",
    "Reliant Kore", "Reliant Mako", "Reliant Sen", "Reliant Tana",
    "Retaliator", "Retaliator", "SRV", "Sabre", "Sabre Comet", "Sabre Raven",
    "San'tok.yāi", "Scythe", "Starfarer", "Starfarer Gemini", "Terrapin",
    "Ursa", "Ursa Fortuna",
    "Valkyrie", "Valkyrie Liberator Edition",
    "Vanguard Harbinger", "Vanguard Hoplite", "Vanguard Sentinel", "Vanguard Warden",
    "Vulcan", "Vulture", "X1", "X1 Force", "X1 Velocity"
  ].freeze

  IMPORTED_SHIPS_HANGAR_XPLOR = (IMPORTED_SHIPS + ["G12a"]).sort.freeze

  def stub_rsi_matrix_and_pledge_store(pledge_store_data)
    matrix_body = File.read("spec/fixtures/rsi/matrix.json")

    stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
      .to_return(status: 200, body: matrix_body)

    stub_request(:post, %r{\Ahttps://robertsspaceindustries.com/graphql})
      .to_return do |request|
        body = JSON.parse(request.body)
        chassis_id = body.first.dig("variables", "query", "ships", "chassisId", 0)
        resources = pledge_store_data[chassis_id.to_s] || []
        {status: 200, body: [{data: {store: {search: {resources: resources}}}}].to_json, headers: {"Content-Type" => "application/json"}}
      end
  end
end
