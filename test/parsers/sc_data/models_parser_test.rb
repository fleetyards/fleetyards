# frozen_string_literal: true

require "test_helper"
require "tmpdir"

# A port declares what may sit in it. The default loadout only says what is in
# it today, so neither the sizes a swap may be nor the item types it must be are
# derivable from the loadout alone -- and the two declarations live in different
# files, in different shapes.
module ScData
  module Parser
    class ModelsParserTest < ActiveSupport::TestCase
      DEFINITION_PATH = "scripts/entities/vehicles/implementations/xml/test_bomber.xml"

      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"

        FileUtils.mkdir_p("#{@raw_path}/Data/Localization/english")
        File.write("#{@raw_path}/Data/Localization/english/global.ini", "")

        write_ship
        write_definition

        @parser = ::ScData::Parser::ModelsParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      private def ports
        @parser.all

        parsed = JSON.parse(File.read("#{@base_folder}/parsed/test/models/test_bomber.json"))

        parsed["loadout"].index_by { |entry| entry["name"] }
      end

      # The port that motivated all of this: an ordnance bay holding an S9
      # torpedo rack, which the files say takes anything from S3 up and is as
      # happy with a bomb rack as with the rack in it.
      test "carries the size range and types a ship's own definition declares" do
        port = ports.fetch("hardpoint_torpedorack")

        assert_equal "3", port["min_size"]
        assert_equal "10", port["max_size"]
        assert_equal ["MissileLauncher", "BombLauncher"], port["types"]
      end

      test "carries the sub types a ship's own definition restricts a type to" do
        port = ports.fetch("hardpoint_torpedorack")

        assert_equal({"MissileLauncher" => ["MissileRack"], "BombLauncher" => ["BombRack"]}, port["sub_types"])
      end

      test "carries the sub types the entity record restricts a type to" do
        assert_equal({"WeaponGun" => ["Gun"]}, ports.fetch("hardpoint_weapon")["sub_types"])
        assert_empty(ports.fetch("hardpoint_relay")["sub_types"])
      end

      # A type and a size are not enough to tell the Eclipse's racks from the
      # Gladiator's -- both are S3-S5 bomb launchers. The shared tag is, and the
      # flags say whether the port may be changed at all.
      test "carries the tags and flags a ship's own definition declares" do
        port = ports.fetch("hardpoint_torpedorack")

        assert_equal ["Eclipse_BombRack"], port["port_tags"]
        assert_equal ["Eclipse_BombRack"], port["required_tags"]
        assert_equal ["editable", "swaponly"], port["flags"]
      end

      test "carries the tags and flags the entity record declares" do
        port = ports.fetch("hardpoint_relay")

        assert_equal ["Relay_Bay"], port["port_tags"]
        assert_equal ["Relay_Bay"], port["required_tags"]
        assert_equal ["uneditable"], port["flags"]
      end

      # The entity record declares a handful of ports of its own rather than in
      # the vehicle definition, so both sources have to be read.
      test "carries what the entity record declares for its own ports" do
        port = ports.fetch("hardpoint_relay")

        assert_equal "0", port["min_size"]
        assert_equal "1", port["max_size"]
        assert_equal ["Relay"], port["types"]
      end

      test "still appends a module port the default loadout leaves empty" do
        port = ports.fetch("hardpoint_front_module")

        assert_nil port["key"]
        assert_equal "3", port["max_size"]
        assert_equal ["Module"], port["types"]
      end

      # The seven collector ships name themselves through a key the export
      # declares with a ",P" marker, so `translate` missed and every one of them
      # loaded nameless.
      test "carries a name the export declares with a plural marker" do
        @parser.translations = {"vehicle_NameTEST_Bomber,P" => "Aegis Sabre Firebird Wikelo War Special"}

        assert_equal "Aegis Sabre Firebird Wikelo War Special", parsed_ship["name"]
      end

      test "carries a name the export declares in another case" do
        @parser.translations = {"vehicle_nametest_bomber" => "Drake Pitbull"}

        assert_equal "Drake Pitbull", parsed_ship["name"]
      end

      # A record may write its finished name where a key belongs. The index
      # cannot answer one, so the literal has to keep reaching the record the
      # way it did through `translate`.
      test "carries a name the record writes out rather than names as a key" do
        write_ship(name: "Mission Prospector")

        @parser.translations = {}

        assert_equal "Mission Prospector", parsed_ship["name"]
      end

      # Only the name. Career and role resolve exactly for every key 4.10.1
      # declares, and a description read through the index would arrive with its
      # newlines already unescaped.
      test "leaves the description as the export writes it" do
        @parser.translations = {"vehicle_DescTEST_Bomber" => 'Focus: Combat\n\nA bomber.'}

        assert_equal 'Focus: Combat\n\nA bomber.', parsed_ship["description"]
      end

      test "carries the ship's own item size" do
        assert_equal "5", parsed_ship["size"]
      end

      test "carries the furniture its rooms hold" do
        FileUtils.mkdir_p("#{@raw_path}/derived")
        File.write("#{@raw_path}/#{::ScData::Parser::ShipInteriors::ROOMS_FILE}", JSON.generate({
          vehicles: {"TEST_Bomber" => {rooms: [{classes: {"Bed_Single_Test" => 2, "Locker_Test" => 1}}]}}
        }))

        assert_equal({"beds" => 2, "lockers" => 1}, parsed_ship["interior"])
      end

      test "carries no interior for a ship whose rooms are unknown" do
        assert_nil parsed_ship["interior"]
      end

      test "carries the services the ship provides to a ship landed on it" do
        write_area_services
        write_ship(components: services_provider)

        assert_equal %w[repair rearm quantum_refuel hydrogen_refuel], parsed_ship["landing_services"]
      end

      test "leaves out repair where the ship turns it off" do
        write_area_services
        write_ship(components: services_provider(repair_available: "0"))

        assert_equal %w[rearm quantum_refuel hydrogen_refuel], parsed_ship["landing_services"]
      end

      test "carries no services for a ship that provides none" do
        write_area_services

        assert_equal [], parsed_ship["landing_services"]
      end

      test "writes each service's icon once, beside the models" do
        write_area_services
        write_ship(components: services_provider)
        icons = "#{@raw_path}/Data/UI/Textures/Vector/General/CommonIcons"
        FileUtils.mkdir_p(icons)
        File.write("#{icons}/icon_services_general.svg", "<svg/>")
        File.write("#{icons}/icon_services_rearm.svg", "<svg/>")

        parsed_ship

        assert_equal(
          {
            "repair" => "ui/textures/vector/general/commonicons/icon_services_general.svg",
            "rearm" => "ui/textures/vector/general/commonicons/icon_services_rearm.svg"
          },
          JSON.parse(File.read("#{@base_folder}/parsed/test/landing_services.json"))
        )
        assert_includes Dir.glob("#{@base_folder}/parsed/test/icons/**/*.svg"),
          "#{@base_folder}/parsed/test/icons/ui/textures/vector/general/commonicons/icon_services_rearm.svg"
      end

      # The areas sit in a container the listed one nests, which is where the
      # Idris keeps its hangar's.
      test "carries the areas its containers mark for servicing a landed ship" do
        write_area_services
        write_containers({
          "objectcontainers/ships/test/bomber/body.socpak" => {"children" => ["objectcontainers/ships/test/bomber/bay.socpak"]},
          "objectcontainers/ships/test/bomber/bay.socpak" => {
            "servicingAreas" => [{
              "name" => "GenericShape-ServicesArea",
              "position" => [0.0, -6.5, -0.75],
              "rotation" => [1.0, 0.0, 0.0, 0.0],
              "shapes" => [{"type" => "Box", "boxMin" => [-7.5, -22.5, -3.0], "boxMax" => [7.5, 22.5, 3.0]}]
            }]
          }
        }, derivation: true)
        write_ship(components: services_provider, object_containers: <<~'XML')
          <SVehicleObjectContainerParams fileName="ObjectContainers\Ships\TEST\bomber\body.socpak" boneName="animated_body">
            <Offset>
              <Rotation x="0" y="0" z="90" />
              <Position x="1" y="2" z="3" />
            </Offset>
          </SVehicleObjectContainerParams>
        XML

        assert_equal(
          [{
            "name" => "GenericShape-ServicesArea",
            "container" => "objectcontainers/ships/test/bomber/bay.socpak",
            "root_container" => "objectcontainers/ships/test/bomber/body.socpak",
            "bone" => "animated_body",
            "offset" => {"position" => [1.0, 2.0, 3.0], "rotation" => [0.0, 0.0, 90.0]},
            "position" => [0.0, -6.5, -0.75],
            "rotation" => [1.0, 0.0, 0.0, 0.0],
            "shapes" => [{"type" => "Box", "boxMin" => [-7.5, -22.5, -3.0], "boxMax" => [7.5, 22.5, 3.0]}]
          }],
          parsed_ship["servicing_areas"]
        )
      end

      test "provides no services where zone servicing has no area to service in" do
        write_area_services
        write_containers({"objectcontainers/ships/test/bomber/body.socpak" => {}}, derivation: true)
        write_ship(components: services_provider, object_containers: '<SVehicleObjectContainerParams fileName="objectcontainers/ships/test/bomber/body.socpak" />')

        assert_equal [], parsed_ship["landing_services"]
      end

      test "keeps the services of an export that does not collect servicing areas" do
        write_area_services
        write_containers({"objectcontainers/ships/test/bomber/body.socpak" => {}})
        write_ship(components: services_provider, object_containers: '<SVehicleObjectContainerParams fileName="objectcontainers/ships/test/bomber/body.socpak" />')

        assert_equal %w[repair rearm quantum_refuel hydrogen_refuel], parsed_ship["landing_services"]
      end

      test "carries no servicing areas for a ship whose containers mark none" do
        write_containers({"objectcontainers/ships/test/bomber/body.socpak" => {}})
        write_ship(object_containers: '<SVehicleObjectContainerParams fileName="objectcontainers/ships/test/bomber/body.socpak" />')

        assert_nil parsed_ship["servicing_areas"]
      end

      private def write_containers(containers, derivation: false)
        file = {containers:}
        file[:derivation] = {servicingAreas: "areas tagged ShipServicingArea"} if derivation

        FileUtils.mkdir_p("#{@raw_path}/derived")
        File.write("#{@raw_path}/#{::ScData::Parser::ServicingAreas::CONTAINERS_FILE}", JSON.generate(file))
      end

      private def services_provider(repair_available: "1")
        <<~XML
          <ShipServicesProviderParams repairAvailable="#{repair_available}" useZoneServicing="1" allowHostile="0" usingRequireBeingLanded="1" servicesClass="00000000-0000-0000-0000-0000000a5e00" />
        XML
      end

      private def write_area_services
        FileUtils.mkdir_p("#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/areaservices")

        File.write("#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/areaservices/test_vehicleservices.xml", <<~XML)
          <AreaServices.TEST_VehicleServices __ref="00000000-0000-0000-0000-0000000a5e00">
            <service>
              <RepairShipServiceDef icon="UI/Textures/Vector/General/CommonIcons/icon_services_general.svg" repairCommodity="00000000-0000-0000-0000-000000000001" />
              <RestockShipServiceDef icon="UI/Textures/Vector/General/CommonIcons/icon_services_rearm.svg" AmmoCommodity="00000000-0000-0000-0000-000000000002" />
              <RefuelShipServiceDefQuantum fuelCommodity="00000000-0000-0000-0000-000000000003" />
              <RefuelShipServiceDefHydrogen fuelCommodity="00000000-0000-0000-0000-000000000004" />
            </service>
          </AreaServices.TEST_VehicleServices>
        XML
      end

      # An AI-only Vanduul hull in 4.10.3 names an implementation file the
      # export does not ship.
      test "still parses a ship whose implementation file is missing" do
        FileUtils.rm("#{@raw_path}/Data/#{DEFINITION_PATH}")

        ship = parsed_ship

        assert_nil ship["mass"]
        assert_nil ship["hull_health"]
      end

      # A snub craft docks through the same vehicle attach port; only the
      # command module's port is tagged as one.
      test "carries the command module a ship docks" do
        write_docking_ship(port_tag: "Dock_Command_Module")

        assert_equal "TEST_Command_Module", parsed_ship["command_module"]
      end

      test "carries no command module for a docked snub craft" do
        write_docking_ship(port_tag: "Dock_Merlin")

        assert_nil parsed_ship["command_module"]
      end

      private def write_docking_ship(port_tag:)
        File.write("#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/entities/spaceships/test_command_module.xml", <<~XML)
          <EntityClassDefinition.TEST_Command_Module __ref="00000000-0000-0000-0000-0000000c0de0">
            <Components>
              <VehicleComponentParams vehicleName="@vehicle_NameTEST_Command_Module" />
            </Components>
          </EntityClassDefinition.TEST_Command_Module>
        XML

        write_ship(
          ports: <<~XML,
            <SItemPortDef Name="hardpoint_docking_module" MinSize="1" MaxSize="1" PortTags="#{port_tag}" Flags="uneditable" />
          XML
          entries: <<~XML
            <SItemPortLoadoutEntryParams itemPortName="hardpoint_docking_module" entityClassReference="00000000-0000-0000-0000-00000000d0c0">
              <loadout>
                <SItemPortLoadoutManualParams>
                  <entries>
                    <SItemPortLoadoutEntryParams itemPortName="itemport_vehicle_attach" entityClassReference="00000000-0000-0000-0000-0000000c0de0" />
                  </entries>
                </SItemPortLoadoutManualParams>
              </loadout>
            </SItemPortLoadoutEntryParams>
          XML
        )
      end

      private def parsed_ship
        @parser.all

        JSON.parse(File.read("#{@base_folder}/parsed/test/models/test_bomber.json"))
      end

      private def write_ship(name: "@vehicle_NameTEST_Bomber", ports: "", entries: "", components: "", object_containers: "")
        FileUtils.mkdir_p("#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/entities/spaceships")

        File.write("#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/entities/spaceships/test_bomber.xml", <<~XML)
          <EntityClassDefinition.TEST_Bomber __ref="00000000-0000-0000-0000-00000000b0b0">
            <Components>
              <VehicleComponentParams vehicleName="#{name}" vehicleDescription="@vehicle_DescTEST_Bomber" vehicleDefinition="#{DEFINITION_PATH}">
                <objectContainers>#{object_containers}</objectContainers>
              </VehicleComponentParams>
              <SAttachableComponentParams>
                <AttachDef Type="NOITEM_Vehicle" SubType="Vehicle_Spaceship" Size="5" />
              </SAttachableComponentParams>
              #{components}
              <SItemPortContainerComponentParams>
                <Ports>
                  <SItemPortDef Name="hardpoint_relay" MinSize="0" MaxSize="1" PortTags="Relay_Bay" RequiredPortTags="$Relay_Bay" Flags="$uneditable">
                    <Types>
                      <SItemPortDefTypes Type="Relay" />
                    </Types>
                  </SItemPortDef>
                  <SItemPortDef Name="hardpoint_weapon" MinSize="1" MaxSize="1">
                    <Types>
                      <SItemPortDefTypes Type="WeaponGun">
                        <SubTypes>
                          <Enum value="Gun" />
                        </SubTypes>
                      </SItemPortDefTypes>
                    </Types>
                  </SItemPortDef>
                  <SItemPortDef Name="hardpoint_front_module" MinSize="3" MaxSize="3">
                    <Types>
                      <SItemPortDefTypes Type="Module" />
                    </Types>
                  </SItemPortDef>
                  #{ports}
                </Ports>
              </SItemPortContainerComponentParams>
              <SEntityComponentDefaultLoadoutParams>
                <loadout>
                  <SItemPortLoadoutManualParams>
                    <entries>
                      <SItemPortLoadoutEntryParams itemPortName="hardpoint_torpedorack" entityClassName="TEST_Torpedo_Rack" />
                      <SItemPortLoadoutEntryParams itemPortName="hardpoint_relay" entityClassName="TEST_Relay" />
                      <SItemPortLoadoutEntryParams itemPortName="hardpoint_weapon" entityClassName="TEST_Gun" />
                      #{entries}
                    </entries>
                  </SItemPortLoadoutManualParams>
                </loadout>
              </SEntityComponentDefaultLoadoutParams>
            </Components>
          </EntityClassDefinition.TEST_Bomber>
        XML
      end

      # The ports sit one level down in the part tree, which is where a real
      # ship keeps them.
      private def write_definition
        FileUtils.mkdir_p("#{@raw_path}/Data/#{File.dirname(DEFINITION_PATH)}")

        File.write("#{@raw_path}/Data/#{DEFINITION_PATH}", <<~XML)
          <Vehicle>
            <Parts>
              <Part name="body" class="Animated" damageMax="1000">
                <Parts>
                  <Part name="hardpoint_torpedorack" class="ItemPort">
                    <ItemPort minSize="3" maxSize="10" flags="editable $swaponly" portTags="Eclipse_BombRack" requiredTags="$Eclipse_BombRack">
                      <Types>
                        <Type type="MissileLauncher" subtypes="MissileRack" />
                        <Type type="BombLauncher" subtypes="BombRack" />
                      </Types>
                    </ItemPort>
                  </Part>
                  <Part name="hardpoint_wing" class="Animated" damageMax="500" />
                </Parts>
              </Part>
            </Parts>
          </Vehicle>
        XML
      end
    end
  end
end
