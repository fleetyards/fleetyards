# frozen_string_literal: true

require "test_helper"
require "tmpdir"

# The rooms export counts the furniture a ship's rooms hold by item, so a bunk
# reads as one bed and a rack says nothing of what it takes. Both are read from
# the usable's own record.
module ScData
  module Parser
    class ShipInteriorsTest < ActiveSupport::TestCase
      setup do
        @base_folder = Dir.mktmpdir
        @base_path = "#{@base_folder}/raw/1.0.0"
        @import_path = "#{@base_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}"

        write_bed("Bed_Single_Test", %w[$anchor_bed])
        write_bed("Bed_Bunk_Test", %w[$anchor_bed $anchor_bed_top $anchor_bed_tv $anchor_bed_tv_top])
        write_bed("Bed_Double_Test", %w[$anchor_bed_left $anchor_bed_right], path: "entities/scitem/ships/usableitems")
        write_bed("Bed_Medical_Test", %w[$anchor_bed], medical: true)
        write_rack
        write_rack("Cargo_Slot_Test")
        write_record("entities/scitem/usables", "Locker_Suit_Test", '<SActorUsableParams fragmentTag="locker" />')
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      test "counts a bed by its berths" do
        write_rooms({"TEST_Ship" => {"Bed_Single_Test" => 1, "Bed_Bunk_Test" => 2, "Bed_Double_Test" => 1}})

        assert_equal 1 + 4 + 2, interiors.for("TEST_Ship")[:beds]
      end

      test "leaves medical beds out of the beds" do
        write_rooms({"TEST_Ship" => {"Bed_Single_Test" => 1, "Bed_Medical_Test" => 2}})

        assert_equal 1, interiors.for("TEST_Ship")[:beds]
      end

      test "counts a bed without a record as one berth" do
        write_rooms({"TEST_Ship" => {"Bed_Unknown_Test" => 2}})

        assert_equal 2, interiors.for("TEST_Ship")[:beds]
      end

      test "reads every slot of a weapon rack, whatever it takes" do
        write_rooms({"TEST_Ship" => {"Weapon_Rack_Test" => 3}})

        rack = interiors.for("TEST_Ship")[:weapon_racks].sole

        assert_equal "Weapon_Rack_Test", rack[:key]
        assert_equal 3, rack[:count]
        assert_equal [
          {min_size: 2, max_size: 3, types: [{type: "WeaponPersonal", sub_types: ["Medium"]}]},
          {min_size: 1, max_size: 1, types: [{type: "WeaponPersonal", sub_types: ["Gadget"]}], required_tags: ["multitool"]},
          {min_size: 1, max_size: 4, types: [{type: "Cargo", sub_types: []}, {type: "Container", sub_types: ["Box"]}]}
        ], rack[:slots]
      end

      test "takes a rack for a rack by what the game calls it, not by its name" do
        write_rooms({"TEST_Ship" => {"Cargo_Slot_Test" => 2}})

        assert_equal [["Cargo_Slot_Test", 2]], interiors.for("TEST_Ship")[:weapon_racks].map { |rack| rack.values_at(:key, :count) }
      end

      test "counts lockers" do
        write_rooms({"TEST_Ship" => {"Locker_Suit_Test" => 2}})

        assert_equal 2, interiors.for("TEST_Ship")[:lockers]
      end

      test "gives a port that names no size the smallest" do
        write_record("entities/scitem/usables", "Weapon_Rack_Unsized", <<~XML)
          <SActorUsableParams fragmentTag="weapon_rack" />
          <SItemPortContainerComponentParams>
            <Ports>
              <SItemPortDef Name="$IP_01" />
            </Ports>
          </SItemPortContainerComponentParams>
        XML
        write_rooms({"TEST_Ship" => {"Weapon_Rack_Unsized" => 1}})

        assert_equal({min_size: 0, max_size: 0, types: []}, interiors.for("TEST_Ship")[:weapon_racks].sole[:slots].sole)
      end

      test "gives a ship whose rooms place nothing nothing at all" do
        write_rooms({"TEST_Ship" => {}})

        assert_empty interiors.for("TEST_Ship")
      end

      test "gives nothing without a rooms file" do
        assert_empty interiors.for("TEST_Ship")
      end

      test "finds a vehicle whatever the case of its key" do
        write_rooms({"TEST_Ship" => {"Bed_Single_Test" => 1}})

        assert_equal 1, interiors.for("test_ship")[:beds]
      end

      private def interiors
        ::ScData::Parser::ShipInteriors.new(base_path: @base_path, import_path: @import_path)
      end

      private def write_rooms(vehicles)
        FileUtils.mkdir_p("#{@base_path}/derived")

        File.write("#{@base_path}/#{::ScData::Parser::ShipInteriors::ROOMS_FILE}", JSON.generate({
          vehicles: vehicles.transform_values do |classes|
            {rooms: [{container: "objectcontainers/ships/test/test_int.socpak", classes:}]}
          end
        }))
      end

      private def write_bed(name, anchors, path: "entities/scitem/usables", medical: false)
        slots = anchors.map { |anchor| %(<PointAlignmentSlot helperName="#{anchor}" />) }.join("\n")

        write_record(path, name, <<~XML)
          #{"<MedBedComponentParams />" if medical}
          <SActorUsableParams fragmentTag="bed">
            <alignmentSlots>
              #{slots}
            </alignmentSlots>
          </SActorUsableParams>
        XML
      end

      private def write_rack(name = "Weapon_Rack_Test")
        write_record("entities/scitem/usables", name, <<~XML)
          <SActorUsableParams fragmentTag="weapon_rack" />
          <SItemPortContainerComponentParams>
            <Ports>
              <SItemPortDef Name="$IP_rifle_01" MinSize="2" MaxSize="3">
                <Types>
                  <SItemPortDefTypes Type="WeaponPersonal">
                    <SubTypes>
                      <Enum value="Medium" />
                    </SubTypes>
                  </SItemPortDefTypes>
                </Types>
              </SItemPortDef>
              <SItemPortDef Name="$IP_multitool_01" MinSize="1" MaxSize="1" RequiredPortTags="multitool">
                <Types>
                  <SItemPortDefTypes Type="WeaponPersonal">
                    <SubTypes>
                      <Enum value="Gadget" />
                    </SubTypes>
                  </SItemPortDefTypes>
                </Types>
              </SItemPortDef>
              <SItemPortDef Name="$proxy_cargo_01" MinSize="1" MaxSize="4">
                <Types>
                  <SItemPortDefTypes Type="Cargo" />
                  <SItemPortDefTypes Type="Container">
                    <SubTypes>
                      <Enum value="Box" />
                    </SubTypes>
                  </SItemPortDefTypes>
                </Types>
              </SItemPortDef>
            </Ports>
          </SItemPortContainerComponentParams>
        XML
      end

      private def write_record(path, name, components)
        FileUtils.mkdir_p("#{@import_path}/#{path}")

        File.write("#{@import_path}/#{path}/#{name.downcase}.xml", <<~XML)
          <EntityClassDefinition.#{name} __type="EntityClassDefinition">
            <Components>
              #{components}
            </Components>
          </EntityClassDefinition.#{name}>
        XML
      end
    end
  end
end
