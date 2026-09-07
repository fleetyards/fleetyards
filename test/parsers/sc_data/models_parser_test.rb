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

      private def write_ship
        FileUtils.mkdir_p("#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/entities/spaceships")

        File.write("#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/entities/spaceships/test_bomber.xml", <<~XML)
          <EntityClassDefinition.TEST_Bomber>
            <Components>
              <VehicleComponentParams vehicleName="@vehicle_NameTEST_Bomber" vehicleDefinition="#{DEFINITION_PATH}" />
              <SItemPortContainerComponentParams>
                <Ports>
                  <SItemPortDef Name="hardpoint_relay" MinSize="0" MaxSize="1" PortTags="Relay_Bay" RequiredPortTags="$Relay_Bay" Flags="$uneditable">
                    <Types>
                      <SItemPortDefTypes Type="Relay" />
                    </Types>
                  </SItemPortDef>
                  <SItemPortDef Name="hardpoint_front_module" MinSize="3" MaxSize="3">
                    <Types>
                      <SItemPortDefTypes Type="Module" />
                    </Types>
                  </SItemPortDef>
                </Ports>
              </SItemPortContainerComponentParams>
              <SEntityComponentDefaultLoadoutParams>
                <loadout>
                  <SItemPortLoadoutManualParams>
                    <entries>
                      <SItemPortLoadoutEntryParams itemPortName="hardpoint_torpedorack" entityClassName="TEST_Torpedo_Rack" />
                      <SItemPortLoadoutEntryParams itemPortName="hardpoint_relay" entityClassName="TEST_Relay" />
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
