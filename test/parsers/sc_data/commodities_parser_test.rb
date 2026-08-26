# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class CommoditiesParserTest < ActiveSupport::TestCase
      RECORDS_PATH = "Data/Libs/Foundry/Records"

      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"

        FileUtils.mkdir_p("#{@raw_path}/Data/Localization/english")
        File.write("#{@raw_path}/Data/Localization/english/global.ini", "")

        @parser = ::ScData::Parser::CommoditiesParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      # Every crate added since 4.x leaves its purchase params at
      # "@LOC_PLACEHOLDER" and names the commodity on the attach definition
      # only, which is how the newer minerals went missing altogether.
      test "#commodities names a crate whose purchase params carry a placeholder" do
        translate("items_commodities_savrilium" => "Savrilium")
        carryable(
          "tractorbeamonly/carryable_tbo_fl_8scu_commodity_metal_savrilium",
          attach_name: "@items_commodities_savrilium",
          display_name: "@LOC_PLACEHOLDER"
        )

        result = @parser.commodities

        assert_equal ["Savrilium"], result.pluck(:name)
        assert_equal "metal", result.first[:commodity_type]
      end

      # The Riccite crate's purchase params offer Potassium, the Tungsten ore
      # crate's offer Titanium ore: the block came with the clone, the attach
      # definition is the record's own.
      test "#commodities prefers the attach definition over the block the crate was cloned with" do
        translate(
          "items_commodities_riccite" => "Riccite",
          "items_commodities_potassium" => "Potassium"
        )
        carryable(
          "tractorbeamonly/carryable_tbo_fl_8scu_commodity_metal_riccite",
          attach_name: "@items_commodities_riccite",
          display_name: "@items_commodities_potassium"
        )

        assert_equal ["Riccite"], @parser.commodities.pluck(:name)
      end

      # A block naming another commodity describes that one's type too, so
      # reading it would file Iron under whatever the donor crate sold.
      test "#commodities ignores the type of a block that names another commodity" do
        translate(
          "items_commodities_iron" => "Iron",
          "items_commodities_widow" => "WiDoW",
          "items_commodities_type_vice" => "Vice"
        )
        carryable(
          "tractorbeamonly/carryable_tbo_fl_8scu_commodity_metal_iron",
          attach_name: "@items_commodities_iron",
          display_name: "@items_commodities_widow",
          display_type: "@items_commodities_type_vice"
        )

        assert_equal "metal", @parser.commodities.first[:commodity_type]
      end

      test "#commodities reads the block of a record that carries no attach definition" do
        translate(
          "items_commodities_agricium" => "Agricium",
          "items_commodities_type_metal" => "Metal"
        )
        commodity_record(
          "metals/agricium",
          display_name: "@items_commodities_agricium",
          display_type: "@items_commodities_type_metal"
        )

        result = @parser.commodities

        assert_equal ["Agricium"], result.pluck(:name)
        assert_equal "metal", result.first[:commodity_type]
      end

      test "#commodities keeps a crate that names itself after its size out of the catalogue" do
        translate(
          "items_commodities_atlasium" => "Atlasium",
          "items_commodities_atlasium_8scu" => "Atlasium (8 SCU)"
        )
        carryable(
          "tractorbeamonly/carryable_tbo_fl_8scu_commodity_metal_atlassium",
          attach_name: "@items_commodities_atlasium_8scu",
          display_name: "@items_commodities_atlasium"
        )

        assert_empty @parser.commodities
      end

      # Ship ammunition is bought by volume and hauled in a generic container,
      # so no crate entity anywhere in the build carries its name.
      test "#commodities names a resource no crate declares" do
        translate("items_commodities_shipammo_size_1" => "Ship Ammunition - Size 1")
        resource_types(
          resource_type("ShipAmmoSize1", display_name: "@items_commodities_shipammo_size_1")
        )

        assert_equal ["Ship Ammunition - Size 1"], @parser.commodities.pluck(:name)
      end

      # The database names each group of resources under the same form of key
      # the crates use for their own type labels.
      test "#commodities keeps the name of a group of resources out of the catalogue" do
        translate("items_commodities_type_metal" => "Metal")
        resource_types(
          resource_type("Metal", display_name: "@items_commodities_type_metal", type: "ResourceTypeGroup")
        )

        assert_empty @parser.commodities
      end

      test "#commodities skips a resource that declares no container to haul it in" do
        translate("items_commodities_oxygen" => "Oxygen")
        resource_types(
          resource_type("Oxygen", display_name: "@items_commodities_oxygen", containers: false)
        )

        assert_empty @parser.commodities
      end

      # The database declares no type, so reading it over a crate would cost the
      # commodity the one thing the crate does say about it.
      test "#commodities leaves a commodity the crates already declared alone" do
        translate(
          "items_commodities_tin" => "Tin",
          "items_commodities_type_metal" => "Metal"
        )
        commodity_record(
          "metals/tin",
          display_name: "@items_commodities_tin",
          display_type: "@items_commodities_type_metal"
        )
        resource_types(
          resource_type("Tin", display_name: "@items_commodities_tin")
        )

        result = @parser.commodities

        assert_equal ["Tin"], result.pluck(:name)
        assert_equal "metal", result.first[:commodity_type]
      end

      private def resource_type(name, display_name:, type: "ResourceType", containers: true)
        <<~XML
          <#{type}.#{name} displayName="#{display_name}" __type="#{type}">
            #{containers_xml if containers}
          </#{type}.#{name}>
        XML
      end

      private def containers_xml
        %(<defaultCargoContainers><SResourceTypeDefaultCargoContainers oneSCU="beef" /></defaultCargoContainers>)
      end

      private def resource_types(*records)
        target = "#{@raw_path}/#{RECORDS_PATH}/#{::ScData::Parser::CommoditiesParser::RESOURCE_TYPES_PATH}"

        FileUtils.mkdir_p(File.dirname(target))

        File.write(target, "<Records>\n#{records.join}</Records>\n")
      end

      private def translate(entries)
        @parser.translations = entries
      end

      private def carryable(path, attach_name:, display_name:, display_type: "@LOC_PLACEHOLDER")
        write_record(
          "entities/scitem/carryables/#{path}",
          <<~XML
            <SCItemPurchasableParams displayName="#{display_name}" displayType="#{display_type}" />
            <SAttachableComponentParams attachToTileItemPort="NoConnection">
              <AttachDef Type="Cargo" SubType="Cargo">
                <Localization Name="#{attach_name}" ShortName="@LOC_EMPTY" Description="@LOC_EMPTY" />
              </AttachDef>
            </SAttachableComponentParams>
          XML
        )
      end

      private def commodity_record(path, display_name:, display_type:)
        write_record(
          "entities/commodities/#{path}",
          %(<SCItemPurchasableParams displayName="#{display_name}" displayType="#{display_type}" />)
        )
      end

      private def write_record(path, components)
        target = "#{@raw_path}/#{RECORDS_PATH}/#{path}.xml"

        FileUtils.mkdir_p(File.dirname(target))

        File.write(target, <<~XML)
          <EntityClassDefinition.Example __ref="00000000-0000-0000-0000-00000000beef">
            <Components>
              #{components}
            </Components>
          </EntityClassDefinition.Example>
        XML
      end
    end
  end
end
