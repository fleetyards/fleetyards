# frozen_string_literal: true

require "test_helper"

class HangarImporterStarship42Test < ActiveSupport::TestCase
  let(:pledge_response_stub) { File.read("test/fixtures/rsi/300i_pledge_page.html") }
  let(:matrix_response_stub) { File.read("test/fixtures/rsi/matrix.json") }

  let(:loader) { ::Rsi::ModelsLoader.new }
  let(:importer) { ::HangarImporter.new }
  let(:import) { ::Imports::HangarImport.create!(user_id: user.id, import: import_file) }
  let(:user) { users :data }
  let(:imported_ships) do
    [
      "100i",
      "125a",
      "135c",
      "300i",
      "315p",
      "325a",
      "350r",
      "600i Executive Edition",
      "600i Explorer",
      "600i Touring",
      "85X",
      "890 Jump",
      "A2 Hercules",
      "Apollo Medivac",
      "Apollo Triage",
      "Ares Inferno",
      "Ares Ion",
      "Arrow",
      "Aurora CL",
      "Aurora ES",
      "Aurora LN",
      "Aurora LX",
      "Aurora MR",
      "Avenger Stalker",
      "Avenger Titan",
      "Avenger Titan Renegade",
      "Avenger Warlock",
      "Ballista",
      "Ballista Dunestalker",
      "Ballista Snowblind",
      "Blade",
      "Buccaneer",
      "C2 Hercules",
      "C8 Pisces",
      "C8X Pisces Expedition",
      "Carrack",
      "Carrack Expedition",
      "Caterpillar",
      "Caterpillar Best In Show Edition",
      "Caterpillar Pirate Edition",
      "Constellation Andromeda",
      "Constellation Aquila",
      "Constellation Phoenix",
      "Constellation Phoenix Emerald",
      "Constellation Taurus",
      "Corsair",
      "Crucible",
      "Cutlass Black",
      "Cutlass Black Best In Show Edition",
      "Cutlass Blue",
      "Cutlass Red",
      "Cyclone",
      "Cyclone AA",
      "Cyclone RC",
      "Cyclone RN",
      "Cyclone TR",
      "Defender",
      "Dragonfly Black",
      "Dragonfly Star Kitten Edition",
      "Dragonfly Yellowjacket",
      "Eclipse",
      "Endeavor",
      "F7A Hornet Mk I",
      "F7C Hornet Mk I",
      "F7C Hornet Wildfire Mk I",
      "F7C-M Super Hornet Heartseeker Mk I",
      "F7C-M Super Hornet Mk I",
      "F7C-R Hornet Tracker Mk I",
      "F7C-S Hornet Ghost Mk I",
      "F8C Lightning",
      "F8C Lightning Executive Edition",
      "Freelancer",
      "Freelancer DUR",
      "Freelancer MAX",
      "Freelancer MIS",
      "Genesis",
      "Gladiator",
      "Gladius",
      "Gladius Valiant",
      "Glaive",
      "Hammerhead",
      "Hammerhead Best In Show Edition",
      "Hawk",
      "Herald",
      "Hull A",
      "Hull B",
      "Hull C",
      "Hull D",
      "Hull E",
      "Hurricane",
      "Idris-M",
      "Idris-P",
      "Idris-P",
      "Javelin",
      "Khartu-Al",
      "Kraken",
      "Kraken Privateer",
      "M2 Hercules",
      "M50",
      "MOLE",
      "MPUV Cargo",
      "MPUV Personnel",
      "Mantis",
      "Merchantman",
      "Mercury",
      "Mole Carbon Edition",
      "Mole Talus Edition",
      "Mustang Alpha",
      "Mustang Alpha Vindicator",
      "Mustang Beta",
      "Mustang Delta",
      "Mustang Gamma",
      "Mustang Omega",
      "Nautilus",
      "Nautilus Solstice Edition",
      "Nova",
      "Nox",
      "Nox Kue",
      "Orion",
      "P-52 Merlin",
      "P-72 Archimedes",
      "P-72 Archimedes Emerald",
      "PTV",
      "Pioneer",
      "Pirate Gladius",
      "Polaris",
      "Prospector",
      "Prowler",
      "Ranger CV",
      "Ranger RC",
      "Ranger TR",
      "Razor",
      "Razor EX",
      "Razor LX",
      "Reclaimer",
      "Reclaimer Best In Show Edition",
      "Redeemer",
      "Reliant Kore",
      "Reliant Mako",
      "Reliant Sen",
      "Reliant Tana",
      "Retaliator",
      "Retaliator",
      "SRV",
      "Sabre",
      "Sabre Comet",
      "Sabre Raven",
      "San'tok.yāi",
      "Scythe",
      "Starfarer",
      "Starfarer Gemini",
      "Terrapin",
      "Ursa",
      "Ursa Fortuna",
      "Valkyrie",
      "Valkyrie Liberator Edition",
      "Vanguard Harbinger",
      "Vanguard Hoplite",
      "Vanguard Sentinel",
      "Vanguard Warden",
      "Vulcan",
      "Vulture",
      "X1",
      "X1 Force",
      "X1 Velocity"
    ]
  end
  let(:import_file) { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/imports/starship42.json")) }

  before do
    Timecop.freeze("2017-01-01 14:00:00")

    stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/pledge/ships/.*/.*})
      .to_return(status: 200, body: pledge_response_stub)

    stub_request(:get, %r{\Ahttps://robertsspaceindustries.com/ship-matrix/index.*})
      .to_return(status: 200, body: matrix_response_stub)

    loader.all
  end

  after do
    Import.destroy_all
    Timecop.return
  end

  it "imports all data" do
    result = ::HangarImporter.new(import).run

    assert_equal(
      {
        missing: [],
        imported: imported_ships,
        success: true
      },
      result
    )
  end
end
