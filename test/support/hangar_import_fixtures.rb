# frozen_string_literal: true

module HangarImportFixtures
  LOADER_FIXTURES_DIR = Rails.root.join("test/fixtures/loader").freeze

  # Inserts the post-loader Manufacturer + Model snapshot from
  # test/fixtures/loader/*.yml. Uses Model.insert_all so the inserts
  # live inside the current test's transactional savepoint and roll
  # back at test teardown — preventing pollution of loader tests that
  # expect a clean DB. (ActiveRecord::FixtureSet.create_fixtures opens
  # its own outer transaction, which escapes the savepoint.)
  # Tables touched by load_loader_fixtures + any preceding loader runs.
  # Cleaned in setup of every loader test so test class ordering can't
  # leak state — Rails' transactional savepoint isn't isolating
  # insert_all data between classes in practice.
  LOADER_TABLES = [Hardpoint, ModelPaint, Model, Manufacturer].freeze

  def clean_loader_tables
    LOADER_TABLES.each(&:delete_all)
  end

  def load_loader_fixtures
    clean_loader_tables
    now = Time.current

    mfr_data = YAML.safe_load_file(LOADER_FIXTURES_DIR.join("manufacturers.yml"))
    mfr_template = Manufacturer.column_names.index_with { nil }
    mfr_id_by_key = {}
    mfr_rows = mfr_data.map do |key, attrs|
      id = ActiveRecord::FixtureSet.identify(key, :uuid)
      mfr_id_by_key[key] = id
      mfr_template.merge(attrs).merge("id" => id, "created_at" => now, "updated_at" => now)
    end
    Manufacturer.insert_all(mfr_rows)

    model_data = YAML.safe_load_file(LOADER_FIXTURES_DIR.join("models.yml"))
    model_template = Model.column_names.index_with { nil }
    model_id_by_key = {}
    model_rows = model_data.map do |key, attrs|
      mfr_key = attrs["manufacturer"]
      id = ActiveRecord::FixtureSet.identify(key, :uuid)
      model_id_by_key[key] = id
      model_template
        .merge(attrs.except("manufacturer"))
        .merge(
          "id" => id,
          "manufacturer_id" => mfr_id_by_key.fetch(mfr_key),
          "created_at" => now,
          "updated_at" => now
        )
    end
    Model.insert_all(model_rows)

    paint_path = LOADER_FIXTURES_DIR.join("model_paints.yml")
    return unless paint_path.exist?

    paint_data = YAML.safe_load_file(paint_path)
    return if paint_data.blank?

    paint_template = ModelPaint.column_names.index_with { nil }
    paint_rows = paint_data.map do |key, attrs|
      model_key = attrs["model"]
      paint_template
        .merge(attrs.except("model"))
        .merge(
          "id" => ActiveRecord::FixtureSet.identify(key, :uuid),
          "model_id" => model_id_by_key.fetch(model_key),
          "created_at" => now,
          "updated_at" => now
        )
    end
    ModelPaint.insert_all(paint_rows)
  end

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
