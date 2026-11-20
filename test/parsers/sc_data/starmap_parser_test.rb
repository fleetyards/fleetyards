# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class StarmapParserTest < ActiveSupport::TestCase
      RECORDS_PATH = "Data/Libs/Foundry/Records"

      TYPES = {
        "SolarSystem" => "00000000-0000-4000-8000-0000000000a1",
        "Star" => "00000000-0000-4000-8000-0000000000a2",
        "Planet" => "00000000-0000-4000-8000-0000000000a3",
        "Moon" => "00000000-0000-4000-8000-0000000000a4",
        "LandingZone" => "00000000-0000-4000-8000-0000000000a5",
        "Manmade" => "00000000-0000-4000-8000-0000000000a6",
        "Outpost" => "00000000-0000-4000-8000-0000000000a7"
      }.freeze

      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"
        @translations = {}
        @tags = []
        @refs = {}
        @overrides = {}

        types_file
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      test "#locations puts the star inside its system and the planet under the star" do
        stanton

        assert_equal ["Stanton System", "Stanton", "Hurston"], chain("Stanton1")
        assert_equal "StantonSolarSystem", location("Stanton1")[:system_key]
        assert_nil location("StantonSolarSystem")[:system_key]
      end

      test "#locations trims a name of the non-breaking space the export ends it with" do
        stanton
        place("Stanton1c", "Magda\u00a0", type: "Moon", parent: "Stanton1")

        assert_equal "Magda", location("Stanton1c")[:name]
      end

      test "#locations reads what kind of world a body is from its description or the overrides" do
        stanton
        place("Stanton2", "Crusader", type: "Planet", parent: "StantonStar", description: "A low mass gas giant.")
        place("Nyx_Delamar", "Delamar", type: "Moon", parent: "Stanton2", description: "A moon-sized asteroid.")
        place("Stanton3", "ArcCorp", type: "Planet", parent: "StantonStar", description: "Buildings cover the planet.")
        place("Stanton2_Belt", "Asteroid Belt", type: "Outpost", parent: "Stanton2", description: "An asteroid field.")
        @overrides = {"Stanton3" => {"body_type" => "city"}}

        assert_equal "gas_giant", location("Stanton2")[:body_type]
        assert_equal "asteroid", location("Nyx_Delamar")[:body_type]
        assert_equal "city", location("Stanton3")[:body_type]
        assert_nil location("Stanton1")[:body_type]
        assert_nil location("Stanton2_Belt")[:body_type]
      end

      test "#locations calls an outpost inside a station or city a clinic or a district" do
        stanton
        place("RR_HUR_LEO", "Everus Harbor", type: "Manmade", parent: "Stanton1", icon: "Station")
        place("RR_HUR_LEO_Clinic", "Everus Harbor Clinic", type: "Outpost", parent: "RR_HUR_LEO")
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")
        place("Lorville_Platform", "Teasa Spaceport", type: "Outpost", parent: "Stanton1_Lorville")
        place("Stanton1_Outpost", "HDMS-Edmond", type: "Outpost", parent: "Stanton1")
        place("Hospital_Stanton1_Lorville", "Maria Pure of Heart", type: "Outpost", parent: "Stanton1_Lorville")

        assert_equal "clinic", location("RR_HUR_LEO_Clinic")[:kind]
        assert_equal "clinic", location("Hospital_Stanton1_Lorville")[:kind]
        assert_equal "district", location("Lorville_Platform")[:kind]
        assert_equal "outpost", location("Stanton1_Outpost")[:kind]
      end

      test "#locations names a place's kind from its map icon before its type" do
        stanton
        place("Nyx_Levski", "Levski", type: "Manmade", parent: "Stanton1", icon: "LandingZone")

        assert_equal "city", location("Nyx_Levski")[:kind]
        assert_equal "planet", location("Stanton1")[:kind]
      end

      test "#locations skips a record whose name is missing or the export's filler" do
        stanton
        place("RR_P6_L1", nil, type: "Manmade", parent: "StantonStar")
        place("ASD_TEMPLATE", "<= UNINITIALIZED =>", type: "Outpost", parent: "Stanton1")
        place("Refinery_0001", "WIP Refinery_0001", type: "Manmade", parent: "StantonStar")

        assert_nil location("RR_P6_L1")
        assert_nil location("ASD_TEMPLATE")
        assert_nil location("Refinery_0001")
      end

      test "#locations drops a named place under an unnamed one" do
        stanton
        place("RR_P6_L1", nil, type: "Manmade", parent: "StantonStar")
        place("Pyro6_L1_Habs", "P6 L1_Habs", type: "Outpost", parent: "RR_P6_L1")

        assert_nil location("Pyro6_L1_Habs")
      end

      # Orison's floating platforms sit under an unnamed cluster record and
      # carry the tag Orison itself carries.
      test "#locations hangs a place under an unnamed one where its tag says it belongs" do
        stanton
        tag("Orison", parent: nil)
        place("Stanton2_Orison", "Orison", type: "LandingZone", parent: "Stanton1", tag: "Orison")
        place("FloatingIsland_ClusterParent", "<= UNINITIALIZED =>", type: "Outpost", parent: "Stanton1", tag: "Orison")
        place("FloatingIsland_AdminCenter", "Admin Center", type: "Outpost", parent: "FloatingIsland_ClusterParent", tag: "Orison")

        assert_equal "Stanton2_Orison", location("FloatingIsland_AdminCenter")[:parent_key]
      end

      # Levski is drawn under the Nyx star and sits inside Delamar.
      test "#locations nests a place where its tag points further down and keeps the map parent" do
        stanton
        tag("Stanton1", parent: nil)
        tag("Levski", parent: "Stanton1")
        place("Nyx_Levski", "Levski", type: "Manmade", parent: "StantonStar", tag: "Levski")

        levski = location("Nyx_Levski")

        assert_equal "Stanton1", levski[:parent_key]
        assert_equal "StantonStar", levski[:map_parent_key]
      end

      # Pyro's outposts carry only the system's tag while their parent is the
      # planet: the tag is coarser, and the parent stays.
      test "#locations keeps the parent where the tag points higher up" do
        stanton
        tag("Stanton", parent: nil)
        place("Stanton1_Outpost", "Shady Glen", type: "Outpost", parent: "Stanton1", tag: "Stanton")

        assert_equal "Stanton1", location("Stanton1_Outpost")[:parent_key]
        assert_nil location("Stanton1_Outpost")[:map_parent_key]
      end

      # Drawn under the star, and tagged with nothing that names the planet.
      test "#locations puts a Lagrange point under its planet and its rest stop under the point" do
        stanton
        tag("HUR_L1", parent: nil)
        place("Stanton1_L1", "HUR L1", type: "Planet", parent: "StantonStar", tag: "HUR_L1")
        place("RR_HUR_L1", "HUR-L1 Green Glade Station", type: "Manmade", parent: "StantonStar")
        place("RR_HUR_L1_CLINIC", "HUR-L1 Green Glade Clinic", type: "Outpost", parent: "RR_HUR_L1")

        assert_equal ["Stanton System", "Stanton", "Hurston", "HUR L1", "HUR-L1 Green Glade Station", "HUR-L1 Green Glade Clinic"], chain("RR_HUR_L1_CLINIC")
        assert_equal "StantonStar", location("RR_HUR_L1")[:map_parent_key]
      end

      # The map hides the point and draws the rest stop at it.
      test "#locations lists a Lagrange point as a station, on the map where its rest stop is" do
        stanton
        place("Stanton1_L1", "HUR L1", type: "Planet", parent: "StantonStar", hidden: true)
        place("RR_HUR_L1", "HUR-L1 Green Glade Station", type: "Manmade", parent: "StantonStar")
        place("Stanton1_L2", "HUR L2", type: "Planet", parent: "StantonStar", hidden: true)

        assert_equal "station", location("Stanton1_L1")[:kind]
        assert location("Stanton1_L1")[:shown_on_starmap]
        refute location("Stanton1_L2")[:shown_on_starmap]
      end

      test "#locations puts an untagged place under the star at the body or base its key names" do
        stanton
        place("TheCollectorAsteroid_Stanton1", "Wikelo Emporium Dasi Station", type: "Manmade", parent: "StantonStar")
        place("Dungeon_Executive_001", "PYAM-EXHANG-0-1", type: "Manmade", parent: "StantonStar")
        place("Dungeon_Executive_001a", "Hangar 01", type: "Outpost", parent: "StantonStar", hidden: true)

        assert_equal "Stanton1", location("TheCollectorAsteroid_Stanton1")[:parent_key]
        assert_equal "StantonStar", location("TheCollectorAsteroid_Stanton1")[:map_parent_key]
        assert_equal "Dungeon_Executive_001", location("Dungeon_Executive_001a")[:parent_key]
      end

      test "#locations puts a place keyed after a moon under that moon" do
        stanton
        place("Stanton1b", "Aberdeen", type: "Moon", parent: "Stanton1")
        place("Mine_Stanton1b", "Klescher Rehabilitation Facility", type: "Manmade", parent: "StantonStar")

        assert_equal "Stanton1b", location("Mine_Stanton1b")[:parent_key]
      end

      test "#locations matches a rest stop coded by its planet's initial and number" do
        place("PyroSolarSystem", "Pyro System", type: "SolarSystem", parent: nil)
        place("PyroStar", "Pyro", type: "Star", parent: nil)
        place("Pyro2", "Monox", type: "Planet", parent: "PyroStar")
        place("Pyro2_L4", "PYR2 L4", type: "Planet", parent: "PyroStar")
        place("RR_P2_L4", "Checkmate", type: "Manmade", parent: "PyroStar")

        assert_equal "Pyro2_L4", location("RR_P2_L4")[:parent_key]
        assert_equal "Pyro2", location("Pyro2_L4")[:parent_key]
      end

      # The export writes line breaks as a literal backslash-n, and Daymar's
      # creatures heading has no colon.
      test "#locations lifts what can be mined and harvested out of the description" do
        stanton
        place("Stanton1a", "Arial", type: "Moon", parent: "Stanton1", description: [
          "This moon was named after the 3rd CEO of Hurston Dynamics.",
          "Potential Ship Mineables:\\nAluminum\\nTin",
          "Potential Hand Mineables:\\nJanalite (Caves only)",
          "Potential Creatures\\nJuvenile Valakkar"
        ].join("\\n\\n"))

        arial = location("Stanton1a")

        assert_equal "This moon was named after the 3rd CEO of Hurston Dynamics.", arial[:description]
        assert_equal %w[ship_mineables hand_mineables creatures], arial[:resources].pluck(:kind)
        assert_equal [{name: "Aluminum", note: nil}, {name: "Tin", note: nil}], arial[:resources].first[:items]
        assert_equal({name: "Janalite", note: "Caves only"}, arial[:resources].second[:items].sole)
      end

      test "#locations places a record keyed after another system in that system" do
        stanton
        translate("Ellis" => "Ellis System", "Ellis_Desc" => "Home of the Murray Cup.")
        place("Ellis3", "Green", type: "Planet", parent: "StantonStar")

        assert_equal ["Ellis System", "Green"], chain("Ellis3")
        assert_equal "Home of the Murray Cup.", location("EllisSolarSystem")[:description]
        assert_equal "StantonStar", location("Ellis3")[:map_parent_key]
      end

      test "#locations leaves out records that hang under no system" do
        stanton
        place("MISSION_QT_Beacon", "Quantum Beacon", type: "Manmade", parent: nil)
        place("MISSION_QT_Distress", "Distress Beacon", type: "Manmade", parent: "Stanton1")

        assert_nil location("MISSION_QT_Beacon")
        assert_nil location("MISSION_QT_Distress")
      end

      test "#locations leaves out templates and spawned props" do
        stanton
        place("MiningFacility_Stanton1_Template", "Outpost 54", type: "Outpost", parent: "Stanton1")
        place("DynamicSpawnedBarge", "Prospect Point", type: "Outpost", parent: "Stanton1")
        place("Base_Sandbox", "BRK-204", type: "Manmade", parent: "Stanton1", hidden: true)
        place("Base_Sandbox_001", "BRK-204 Copy", type: "Manmade", parent: "Stanton1")

        assert_nil location("MiningFacility_Stanton1_Template")
        assert_nil location("DynamicSpawnedBarge")
        assert_nil location("Base_Sandbox")
        assert location("Base_Sandbox_001")
      end

      test "#locations folds a place named like its parent into it" do
        stanton
        place("Orison_VisionCenter", "Vision Center", type: "Outpost", parent: "Stanton1")
        place("Orison_VisionCenter_Label", "Vision Center", type: "Outpost", parent: "Orison_VisionCenter")

        assert_nil location("Orison_VisionCenter_Label")
        assert_equal 2, location("Orison_VisionCenter")[:sc_refs].size
      end

      test "#locations applies the overrides" do
        stanton
        place("Gateway_Clinic", "Terra Gateway Clinic", type: "Outpost", parent: "Stanton1")
        place("Jericho_Copy", "INS Jericho", type: "Manmade", parent: "Stanton1")
        place("Base_01", "Mining Base #1", type: "Outpost", parent: "Stanton1", hidden: true)
        place("Base_02", "Mining Base #1", type: "Outpost", parent: "Stanton1")

        @overrides = {
          "StantonStar" => {"description" => "A class-G main sequence star."},
          "Gateway_Clinic" => {"name" => "Clinic"},
          "Jericho_Copy" => {"skip" => true},
          "Base_01" => {"merge" => ["Base_02"]}
        }

        assert_equal "Clinic", location("Gateway_Clinic")[:name]
        assert_equal "A class-G main sequence star.", location("StantonStar")[:description]
        assert_nil location("Jericho_Copy")
        assert_nil location("Base_02")
        assert_equal 2, location("Base_01")[:sc_refs].size
        assert location("Base_01")[:shown_on_starmap]
      end

      test "#locations keeps a description the export gives over the override's" do
        place("StantonSolarSystem", "Stanton System", type: "SolarSystem", parent: nil)
        place("StantonStar", "Stanton", type: "Star", parent: nil, description: "A K-type star.")

        @overrides = {"StantonStar" => {"description" => "A class-G main sequence star."}}

        assert_equal "A K-type star.", location("StantonStar")[:description]
      end

      test "#all leaves no places behind when the export has none" do
        export = "#{@base_folder}/parsed/test/locations"
        FileUtils.mkdir_p(export)
        File.write("#{export}/stale.json", "{}")

        parser.all

        assert_not File.exist?("#{export}/stale.json")
      end

      test "#locations carries how the in-game map shows a place" do
        stanton
        place("Nyx_Levski", "Levski", type: "Manmade", parent: "Stanton1", permanent: true)
        place("Clinic", "Clinic", type: "Outpost", parent: "Stanton1", hidden: true, parent_only: true)

        levski = location("Nyx_Levski")
        clinic = location("Clinic")

        assert_equal [true, false, true, true], levski.values_at(:shown_on_starmap, :shown_with_parent_only, :always_shown, :quantum_travel_destination)
        assert_equal [false, true, false], clinic.values_at(:shown_on_starmap, :shown_with_parent_only, :always_shown)
      end

      test "#locations links a mission template to the specific place its deepest tag stands for" do
        stanton
        tag("Stanton1", parent: nil)
        tag("Lorville", parent: "Stanton1")
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1", tag: "Lorville")
        mission_template("LandingZone_Lorville", "10000000-0000-4000-8000-000000000001", tags: %w[Stanton1 Lorville])
        mission_template("Hurston_Anywhere", "10000000-0000-4000-8000-000000000002", tags: %w[Stanton1])

        assert_equal ["10000000-0000-4000-8000-000000000001"], location("Stanton1_Lorville")[:mission_template_refs]
        assert_empty location("Stanton1")[:mission_template_refs]
      end

      test "#locations counts a station's hangars, pads and docking tubes by size" do
        stanton
        place("RR_HUR_LEO", "Everus Harbor", type: "Manmade", parent: "Stanton1", icon: "Station")
        landing_zones([
          landing_zone("RR_HUR_LEO", zones: [
            zone("rs_ext_hur_leo",
              hangars: [hangar("Large", 6), hangar("Small", 4, dimensions: [24, 32, 16])],
              pads: [pad("Medium", 2, dimensions: [58, 88, 32]), pad("Small", 3, vehicles: true, dimensions: [8, 16, 6])],
              tubes: 2),
            zone("secdock_hur_leo", pads: [pad("Medium", 1, dimensions: [58, 88, 32])], tubes: 1)
          ])
        ])

        facilities = location("RR_HUR_LEO")[:facilities]

        assert_equal [
          {size: "large", count: 6, length: 128, beam: 72, height: 48, door: "front"},
          {size: "small", count: 4, length: 32, beam: 24, height: 16, door: "front"}
        ], facilities[:hangars]
        assert_equal [{size: "medium", count: 3, length: 88, beam: 58, height: 32, atc_assigned: false}], facilities[:landing_pads]
        assert_equal [{size: "small", count: 3, length: 16, beam: 8, height: 6, atc_assigned: false}], facilities[:vehicle_pads]
        assert_equal 3, facilities[:docking_tubes]
        assert_nil location("Stanton1")[:facilities]
      end

      test "#locations makes a city's spaceport a place inside it, and the city keeps the rest" do
        stanton
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")
        @overrides = {"Stanton1_Lorville_Spaceport" => {"name" => "Teasa Spaceport"}}
        landing_zones([
          landing_zone("Stanton1_Lorville", zones: [
            zone("lorville_sp_ext", hangars: [hangar("XLarge", 3)]),
            zone("lorville_gate_01", pads: [pad("Small", 4, vehicles: true)])
          ])
        ])

        spaceport = location("Stanton1_Lorville_Spaceport")

        assert_equal ["Teasa Spaceport", "spaceport", "Stanton1_Lorville", "StantonSolarSystem"],
          spaceport.values_at(:name, :kind, :parent_key, :system_key)
        assert_equal [3], spaceport[:facilities][:hangars].pluck(:count)
        assert_empty location("Stanton1_Lorville")[:facilities][:hangars]
        assert_equal [4], location("Stanton1_Lorville")[:facilities][:vehicle_pads].pluck(:count)
      end

      test "#locations names a spaceport after its city when the overrides do not" do
        stanton
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")
        landing_zones([
          landing_zone("Stanton1_Lorville", zones: [zone("lorville_sp_ext", hangars: [hangar("Large", 1)]), zone("lorville_gate_01")])
        ])

        assert_equal "Lorville Spaceport", location("Stanton1_Lorville_Spaceport")[:name]
      end

      test "#locations makes the spaceport even where it is the city's only zone" do
        stanton
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")
        landing_zones([landing_zone("Stanton1_Lorville", zones: [zone("lorville_sp_ext", hangars: [hangar("Large", 2)])])])

        assert_equal [2], location("Stanton1_Lorville_Spaceport")[:facilities][:hangars].pluck(:count)
        assert_nil location("Stanton1_Lorville")[:facilities]
      end

      test "#locations keeps every zone on a city with no spaceport of its own" do
        stanton
        place("Nyx_Levski", "Levski", type: "LandingZone", parent: "Stanton1")
        landing_zones([landing_zone("Nyx_Levski", zones: [zone("levski_all", hangars: [hangar("Large", 10)])])])

        assert_equal [10], location("Nyx_Levski")[:facilities][:hangars].pluck(:count)
        assert_nil location("Nyx_Levski_Spaceport")
      end

      test "#locations finds the place a landing zone belongs to by the ref a merge left on it" do
        stanton
        place("RR_HUR_LEO", "Everus Harbor", type: "Manmade", parent: "Stanton1", icon: "Station")
        place("RR_HUR_LEO_2", "Everus Harbor", type: "Manmade", parent: "Stanton1", icon: "Station")
        @overrides = {"RR_HUR_LEO" => {"merge" => ["RR_HUR_LEO_2"]}}
        landing_zones([
          landing_zone("RR_HUR_LEO_2", zones: [zone("rs_ext_hur_leo", hangars: [hangar("Medium", 2)])]),
          landing_zone(nil, ref: "00000000-0000-4000-8000-00000000dead", zones: [zone("collector_ext", hangars: [hangar("XLarge", 12)])])
        ])

        assert_equal [2], location("RR_HUR_LEO")[:facilities][:hangars].pluck(:count)
        assert_nil location("RR_HUR_LEO_2")
      end

      test "#locations follows a merge from the record key when the ref matches nothing" do
        stanton
        place("RR_HUR_LEO", "Everus Harbor", type: "Manmade", parent: "Stanton1", icon: "Station")
        place("RR_HUR_LEO_2", "Everus Harbor", type: "Manmade", parent: "Stanton1", icon: "Station")
        @overrides = {"RR_HUR_LEO" => {"merge" => ["RR_HUR_LEO_2"]}}
        landing_zones([
          landing_zone("RR_HUR_LEO_2", ref: "00000000-0000-4000-8000-00000000beef", zones: [zone("rs_ext_hur_leo", hangars: [hangar("Medium", 2)])])
        ])

        assert_equal [2], location("RR_HUR_LEO")[:facilities][:hangars].pluck(:count)
      end

      test "#locations leaves facilities out of an export without the landing zones file" do
        stanton
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")

        assert_nil location("Stanton1_Lorville")[:facilities]
        assert_nil location("Stanton1_Lorville_Spaceport")
      end

      test "#locations places a record where the system's object container puts it" do
        stanton
        place("Stanton3_Area18", "Area18", type: "LandingZone", parent: "Stanton1")
        placements([placement("Stanton1", [12_850_457_093.0, 0, 0]), placement("Stanton3_Area18", [18_586_917_331.5, -22_152_033_654.0, -262_094.0])])

        assert_equal [12_850_457_093.0, 0.0, 0.0], location("Stanton1")[:position]
        assert_equal [18_586_917_331.5, -22_152_033_654.0, -262_094.0], location("Stanton3_Area18")[:position]
        assert_nil location("StantonSolarSystem")[:position]
      end

      test "#locations takes a body's radius from its placement, and no other place's" do
        stanton
        place("Stanton3_Area18", "Area18", type: "LandingZone", parent: "Stanton1")
        placements([placement("Stanton1", [12_850_457_093.0, 0, 0], size: 1_000_000.0), placement("Stanton3_Area18", [1, 2, 3], size: 4_000.0)])

        assert_equal 1_000_000.0, location("Stanton1")[:radius]
        assert_nil location("Stanton3_Area18")[:radius]
      end

      test "#locations gives a record placed more than once no position" do
        stanton
        place("QV_Station", "QV Logistics Station", type: "Outpost", parent: "Stanton1")
        placements([placement("QV_Station", [1, 2, 3]), placement("QV_Station", [4, 5, 6])])

        assert_nil location("QV_Station")[:position]
      end

      test "#locations takes the places a planet builds from location templates" do
        stanton
        template = ->(id, parent, name, level, template = "#{level.downcase}_tpl") do
          {id:, parent:, name:, class: "BaseLocationTemplate", locationClass: level, template:, record: nil, pos: [1.0, 2.0, 3.0]}
        end

        placements([
          {id: "hurston", record: ref_for("Stanton1"), name: "Hurston", pos: [12_850_457_093.0, 0, 0]},
          template.call("sector", "hurston", "Fenwick Territories", "Sector"),
          template.call("cluster", "sector", nil, "Cluster"),
          template.call("site", "cluster", "Covalex Capital Z3SP02", "Location", "location_logistics_hub"),
          template.call("camp-1", "cluster", "Campsite", "Location"),
          template.call("camp-2", "cluster", "Campsite", "Location"),
          template.call("nameless", "cluster", nil, "Location")
        ])

        sector = location("sector_tpl@sector")
        site = location("location_logistics_hub@site")

        assert_equal "district", sector[:kind]
        assert_equal "Stanton1", sector[:parent_key]
        assert_equal "StantonSolarSystem", sector[:system_key]
        assert_equal "outpost", site[:kind]
        assert_equal "sector_tpl@sector", site[:parent_key]
        assert_equal [1.0, 2.0, 3.0], site[:position]
        assert_equal ["site"], site[:sc_refs]

        names = parser.locations.pluck(:name)
        refute_includes names, "Campsite"
        refute_includes names.compact, nil
      end

      test "#locations puts a place under the jurisdiction above it, lawful where it keeps any law" do
        jurisdiction("uee", "UEE", laws: true)
        jurisdiction("hurston", "Hurston Dynamics", parent: "uee", defers: true)
        jurisdiction("unclaimed", "Unclaimed Space")
        place("StantonSolarSystem", "Stanton System", type: "SolarSystem", parent: nil)
        place("StantonStar", "Stanton", type: "Star", parent: nil)
        place("Stanton1", "Hurston", type: "Planet", parent: "StantonStar", jurisdiction: "hurston")
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")
        place("Stanton2", "Crusader", type: "Planet", parent: "StantonStar", jurisdiction: "unclaimed")

        assert_equal "Hurston Dynamics", location("Stanton1_Lorville")[:jurisdiction]
        assert location("Stanton1_Lorville")[:lawful]
        assert_equal "Unclaimed Space", location("Stanton2")[:jurisdiction]
        assert_equal false, location("Stanton2")[:lawful]
        assert_nil location("StantonStar")[:jurisdiction]
      end

      test "#locations reads what the starmap lists a place as offering, in the app's order" do
        amenity_types("Vehicle Services", "Clinic", "Hangar L", "Spa Day")
        stanton
        place("Stanton1_L1", "HUR-L1", type: "Manmade", parent: "Stanton1", amenities: ["Clinic", "Vehicle Services", "Spa Day", "Hangar L"])

        assert_equal %w[vehicle_services clinic hangar_l], location("Stanton1_L1")[:amenities]
        assert_equal [], location("Stanton1")[:amenities]
      end

      test "#locations has no positions for an export without placements" do
        stanton

        assert_nil location("Stanton1")[:position]
      end

      test "#locations carries a body's starmap texture into the parsed tree" do
        stanton
        place("Stanton3_Area18", "Area18", type: "LandingZone", parent: "Stanton1")
        starmap_materials(
          {
            "materials/ui/starmap/planetsmoons/stanton/ui_sm_stanton_1_hurston.mtl" => {
              records: [ref_for("Stanton1"), ref_for("Stanton3_Area18")],
              maps: {surface: "starmap_materials/ui_sm_stanton_1_hurston.webp", dotgrid: "starmap_materials/dots.webp"}
            }
          }
        )

        assert_equal "starmap_materials/ui_sm_stanton_1_hurston.webp", location("Stanton1")[:starmap_texture]
        assert_nil location("Stanton3_Area18")[:starmap_texture]
        assert File.file?("#{@base_folder}/parsed/test/starmap_materials/ui_sm_stanton_1_hurston.webp")
      end

      test "#locations carries a body's elevation and cloud cover by its starmap record" do
        stanton
        starmap_materials(
          {},
          bodies: {
            ref_for("Stanton1") => {
              name: "Hurston",
              maps: {elevation: "starmap_materials/stanton1_global_elev.png", clouds: "starmap_materials/stanton1_clouds_global.webp"}
            }
          }
        )

        assert_equal "starmap_materials/stanton1_global_elev.png", location("Stanton1")[:starmap_elevation]
        assert_equal "starmap_materials/stanton1_clouds_global.webp", location("Stanton1")[:starmap_clouds]
        assert_nil location("Stanton1")[:starmap_texture]
        assert File.file?("#{@base_folder}/parsed/test/starmap_materials/stanton1_global_elev.png")
      end

      test "#locations takes no texture from outside the textures folder" do
        stanton
        starmap_materials(
          {"materials/hurston.mtl" => {records: [ref_for("Stanton1")], maps: {surface: "starmap_materials/../../secret.webp"}}},
          bodies: {ref_for("Stanton1") => {maps: {elevation: "../secret.png"}}}
        )

        assert_nil location("Stanton1")[:starmap_texture]
        assert_nil location("Stanton1")[:starmap_elevation]
      end

      test "#locations has no textures for an export without starmap materials" do
        stanton

        assert_nil location("Stanton1")[:starmap_texture]
      end

      test "#locations says whether a place is an armistice zone as a whole or in parts" do
        stanton
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")
        place("Stanton1_L1", "HUR-L1", type: "Manmade", parent: "Stanton1")
        place("Stanton1_Outpost", "Outpost", type: "Outpost", parent: "Stanton1")
        place("Stanton1_Mine", "Mining Base", type: "Outpost", parent: "Stanton1")
        area_zones(
          area_zone("Stanton1_Lorville", "armistice", contains: true, params: {noFPSWeapons: 1}),
          area_zone("Stanton1_L1", "armistice", params: {noFPSWeapons: 1, noTractorBeam: "1"}),
          area_zone("Stanton1_Mine", "armistice", contains: true, params: {noFPSWeapons: 0, noShipWeapons: 0}),
          area_zone("Stanton1", "armistice", contains: true, params: {noFPSWeapons: 1})
        )

        assert_equal "whole", location("Stanton1_Lorville")[:armistice]
        assert_equal "partial", location("Stanton1_L1")[:armistice]
        assert_nil location("Stanton1_Outpost")[:armistice]
        assert_nil location("Stanton1_Mine")[:armistice]
        assert_nil location("Stanton1")[:armistice]
      end

      test "#locations marks restricted areas only where they keep people on foot out" do
        stanton
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")
        place("Stanton1_L1", "HUR-L1", type: "Manmade", parent: "Stanton1")
        place("Stanton1_Mine", "Mining Base", type: "Outpost", parent: "Stanton1")
        foot = {state: "Disallow", affectActorsOnFoot: 1, affectShips: 1}
        area_zones(
          area_zone("Stanton1_Lorville", "restricted", params: foot, layer: "lorville.soc"),
          area_zone("Stanton1_L1", "restricted", params: {state: "Disallow", affectActorsOnFoot: 0, affectGroundVehicles: 1}),
          area_zone("Stanton1_L1", "restricted", params: foot.merge(state: "Despawn")),
          area_zone("Stanton1_Mine", "restricted", params: foot, layer: "npc_hangar_lrgfrnt_001.soc"),
          area_zone("Stanton1", "restricted", contains: true, params: foot)
        )

        assert location("Stanton1_Lorville")[:restricted_areas]
        assert_equal false, location("Stanton1_L1")[:restricted_areas]
        assert_equal false, location("Stanton1_Mine")[:restricted_areas]
        assert_nil location("Stanton1")[:restricted_areas]
      end

      test "#locations reads zones by each zone's record, whatever its id" do
        stanton
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")
        place("Stanton1_L1", "HUR-L1", type: "Manmade", parent: "Stanton1")
        area_zones(
          area_zone("Stanton1_Lorville", "armistice", id: "shared", contains: true, params: {noFPSWeapons: 1}),
          area_zone("Stanton1_L1", "armistice", id: "shared", params: {noFPSWeapons: 1})
        )

        assert_equal "whole", location("Stanton1_Lorville")[:armistice]
        assert_equal "partial", location("Stanton1_L1")[:armistice]
      end

      test "#locations knows nothing of zones for an export without them" do
        stanton
        place("Stanton1_Lorville", "Lorville", type: "LandingZone", parent: "Stanton1")

        assert_nil location("Stanton1_Lorville")[:armistice]
        assert_nil location("Stanton1_Lorville")[:restricted_areas]
      end

      private def area_zones(*zones)
        target = "#{@raw_path}/derived/zones.json"

        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, JSON.generate({zones:, byRecord: {}}))
      end

      private def area_zone(record_key, kind, params:, contains: false, id: SecureRandom.uuid, layer: "zone.soc")
        {id:, kind:, layer:, params:, record: ref_for(record_key), containsParent: contains, areas: []}
      end

      private def starmap_materials(materials, bodies: {})
        target = "#{@raw_path}/derived/starmap_materials.json"

        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, JSON.generate({derivation: {}, materials:, bodies:}))

        (materials.values + bodies.values).each do |material|
          material[:maps].each_value do |path|
            next if path.include?("..")

            FileUtils.mkdir_p(File.dirname("#{@raw_path}/derived/#{path}"))
            File.write("#{@raw_path}/derived/#{path}", "webp")
          end
        end
      end

      private def parser
        tags_file
        File.write("#{localization_path}/global.ini", @translations.map { |key, value| "#{key}=#{value}" }.join("\n"))

        ::ScData::Parser::StarmapParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test", overrides: @overrides
        )
      end

      private def location(key)
        (@locations ||= parser.locations).find { |item| item[:sc_key] == key }
      end

      private def chain(key)
        names = []
        item = location(key)

        while item
          names.unshift(item[:name])
          item = item[:parent_key] && location(item[:parent_key])
        end

        names
      end

      private def stanton
        place("StantonSolarSystem", "Stanton System", type: "SolarSystem", parent: nil)
        place("StantonStar", "Stanton", type: "Star", parent: nil)
        place("Stanton1", "Hurston", type: "Planet", parent: "StantonStar")
      end

      private def place(key, name, type:, parent:, icon: nil, tag: nil, hidden: false, parent_only: false, permanent: false, description: nil, jurisdiction: nil, amenities: [])
        ref = ref_for(key)
        name_key = "loc_#{key.downcase}"
        @translations[name_key] = name if name
        @translations["#{name_key}_desc"] = description if description

        attributes = {
          name: "@#{name_key}",
          description: description ? "@#{name_key}_desc" : nil,
          type: TYPES.fetch(type),
          navIcon: icon || "Default",
          parent: parent ? ref_for(parent) : nil,
          locationHierarchyTag: tag ? tag_ref(tag) : nil,
          hideInStarmap: hidden ? 1 : 0,
          onlyShowWhenParentSelected: parent_only ? 1 : 0,
          overridePermanent: permanent ? "True" : "NoOverride",
          jurisdiction: jurisdiction ? ref_for("jurisdiction_#{jurisdiction}") : nil
        }.compact

        references = amenities.map { |amenity| %(<Reference value="#{amenity_ref(amenity)}" />) }.join
        body = %(<StarMapObjectLocationParams setEntityLocationOnEnter="1" /><amenities>#{references}</amenities>)

        write("starmap/pu/#{key.downcase}", "StarMapObject", key, ref, attributes, body:)
      end

      private def amenity_types(*names)
        records = names.map do |name|
          ref = amenity_ref(name)
          %(<StarMapAmenityTypeEntry.#{ref} name="#{name}" __type="StarMapAmenityTypeEntry" __ref="#{ref}" />)
        end

        write_file("starmapamenitytypes/starmapamenitytypes.records.xml", "<Records>#{records.join}</Records>")
      end

      private def amenity_ref(name)
        @refs["amenity:#{name}"] ||= Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "amenity-#{name}")
      end

      private def jurisdiction(key, name, parent: nil, defers: false, laws: false)
        @translations["jurisdiction_#{key}"] = name
        attributes = {
          name: "@jurisdiction_#{key}",
          parentJurisdiction: parent ? ref_for("jurisdiction_#{parent}") : nil,
          respectsParentJurisdictionLaws: defers ? 1 : 0
        }.compact
        body = laws ? %(<infractions><Infraction definition="x" /></infractions>) : ""

        write("lawsystem/jurisdictions/#{key}", "Jurisdiction", key, ref_for("jurisdiction_#{key}"), attributes, body:)
      end

      private def landing_zones(locations)
        target = "#{@raw_path}/derived/landingzones.json"

        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, JSON.generate({padSizes: [], locations:}))
      end

      private def placements(objects)
        target = "#{@raw_path}/derived/starmap.json"

        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, JSON.generate({systems: [], objects:}))
      end

      private def placement(key, pos, size: nil)
        {record: ref_for(key), name: key, pos:, size:}
      end

      private def landing_zone(key, zones:, ref: nil)
        {name: key, starmapRecord: key, starmapRef: ref || (key && ref_for(key)), container: zones.first[:container], zones:}
      end

      private def zone(container, hangars: [], pads: [], tubes: 0)
        {container:, hangars:, pads:, dockingTubes: tubes}
      end

      private def hangar(size, count, dimensions: [72, 128, 48])
        {size:, door: "front", count:, padDimensions: dimensions}
      end

      private def pad(size, count, vehicles: false, dimensions: [56, 88, 32])
        {size:, sizeSource: "fit", dimensions:, groundVehiclesOnly: vehicles, atcAssigned: false, count:}
      end

      private def mission_template(key, ref, tags:)
        references = tags.map { |tag| %(<Reference value="#{tag_ref(tag)}" />) }.join

        write("missiondata/pu_locations/templates/#{key.downcase}", "MissionLocationTemplate", key, ref, {},
          body: %(<locationData disabled="0"><generalTags><tags>#{references}</tags></generalTags></locationData>))
      end

      private def translate(entries)
        @translations.merge!(entries)
      end

      private def tag(name, parent:)
        @tags << {name:, ref: tag_ref(name), parent: parent && tag_ref(parent)}
      end

      private def tag_ref(name)
        @refs["tag:#{name}"] ||= Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "tag-#{name}")
      end

      private def ref_for(key)
        @refs[key] ||= Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "starmap-#{key}")
      end

      private def localization_path
        "#{@raw_path}/Data/Localization/english".tap { |path| FileUtils.mkdir_p(path) }
      end

      private def types_file
        records = TYPES.map do |name, ref|
          quantum = %w[Planet Moon LandingZone Manmade Outpost].include?(name) ? 1 : 0
          %(<StarMapObjectType.#{ref} name="#{name}" validQuantumTravelDestination="#{quantum}" __type="StarMapObjectType" __ref="#{ref}"><markerConfig /></StarMapObjectType.#{ref}>)
        end

        write_file("starmap/starmapobjecttypes.records.xml", "<Records>#{records.join}</Records>")
      end

      private def tags_file
        records = @tags.map do |tag|
          children = @tags.select { |child| child[:parent] == tag[:ref] }.map { |child| %(<Reference value="#{child[:ref]}" />) }.join

          %(<Tag.#{tag[:ref]} tagName="#{tag[:name]}" __type="Tag" __ref="#{tag[:ref]}"><children>#{children}</children></Tag.#{tag[:ref]}>)
        end

        write_file("TagDatabase/tagdatabase.tagdatabase.records.xml", "<Records>#{records.join}</Records>")
      end

      # A child element on every record, as the export has: an element with
      # attributes alone would have its `type` attribute read as a typecast.
      private def write(path, element, key, ref, attributes, body: "<StarMapObjectLocationParams setEntityLocationOnEnter=\"1\" />")
        listed = attributes.map { |name, value| %(#{name}="#{value}") }.join(" ")

        write_file("#{path}.xml", <<~XML)
          <#{element}.#{key} #{listed} __type="#{element}" __ref="#{ref}">
            #{body}
          </#{element}.#{key}>
        XML
      end

      private def write_file(path, content)
        target = "#{@raw_path}/#{RECORDS_PATH}/#{path}"

        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, content)
      end
    end
  end
end
