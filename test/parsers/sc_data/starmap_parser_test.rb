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

        assert_nil location("RR_P6_L1")
        assert_nil location("ASD_TEMPLATE")
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

      test "#locations matches a rest stop coded by its planet's initial and number" do
        place("PyroSolarSystem", "Pyro System", type: "SolarSystem", parent: nil)
        place("PyroStar", "Pyro", type: "Star", parent: nil)
        place("Pyro2", "Monox", type: "Planet", parent: "PyroStar")
        place("Pyro2_L4", "PYR2 L4", type: "Planet", parent: "PyroStar")
        place("RR_P2_L4", "Checkmate", type: "Manmade", parent: "PyroStar")

        assert_equal "Pyro2_L4", location("RR_P2_L4")[:parent_key]
        assert_equal "Pyro2", location("Pyro2_L4")[:parent_key]
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

        assert_nil location("MISSION_QT_Beacon")
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
          "Gateway_Clinic" => {"name" => "Clinic"},
          "Jericho_Copy" => {"skip" => true},
          "Base_01" => {"merge" => ["Base_02"]}
        }

        assert_equal "Clinic", location("Gateway_Clinic")[:name]
        assert_nil location("Jericho_Copy")
        assert_nil location("Base_02")
        assert_equal 2, location("Base_01")[:sc_refs].size
        assert location("Base_01")[:shown_on_starmap]
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

      private def place(key, name, type:, parent:, icon: nil, tag: nil, hidden: false, parent_only: false, permanent: false)
        ref = ref_for(key)
        name_key = "loc_#{key.downcase}"
        @translations[name_key] = name if name

        attributes = {
          name: "@#{name_key}",
          type: TYPES.fetch(type),
          navIcon: icon || "Default",
          parent: parent ? ref_for(parent) : nil,
          locationHierarchyTag: tag ? tag_ref(tag) : nil,
          hideInStarmap: hidden ? 1 : 0,
          onlyShowWhenParentSelected: parent_only ? 1 : 0,
          overridePermanent: permanent ? "True" : "NoOverride"
        }.compact

        write("starmap/pu/#{key.downcase}", "StarMapObject", key, ref, attributes)
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
