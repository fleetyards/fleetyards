# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class CommoditiesParserTest < ActiveSupport::TestCase
      RECORDS_PATH = "Data/Libs/Foundry/Records"

      AMMUNITION_REF = "1fdb2e84-1622-4685-8194-2d108498d90f"
      ORE_REF = "551cf88d-c09f-46e3-99b3-66c60bb65af1"
      METAL_REF = "1b4c4042-5fdc-4b52-bec4-07085cb3520a"

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

      # Ship Ammunition is the one good the game names from outside the
      # commodity namespace: its record borrows the ammo crate item's keys, so
      # it went missing altogether and its prices had nothing to attach to.
      test "#commodities names the good that borrows the ammo crate's keys" do
        translate(
          "item_NameAmmoCrate" => "Ship Ammunition",
          "item_DescAmmoCrate" => "Refill your ship's ballistic ammunition.",
          "items_commodities_type_processedGoods" => "Processed Goods"
        )
        commodity_record(
          "processedgoods/shipammunition",
          display_name: "@item_NameAmmoCrate",
          display_type: "@items_commodities_type_processedGoods"
        )

        commodity = @parser.commodities.first

        assert_equal "items_commodities_shipammunition", commodity[:sc_key]
        assert_equal "Ship Ammunition", commodity[:name]
        assert_equal "Refill your ship's ballistic ammunition.", commodity[:description]
        assert_equal "processed_goods", commodity[:commodity_type]
      end

      # Only that one is aliased. The rest of what the database names from
      # outside the namespace is a helmet and two unnamed mission props, and
      # a rule reading any key at all would carry them in.
      test "#commodities keeps a resource named from outside the namespace out of the catalogue" do
        translate("item_Name_basl_combat_light_helmet_02_01_01" => "Ace Interceptor Helmet")
        resource_types(
          resource_type("AceInterceptorHelmet", display_name: "@item_Name_basl_combat_light_helmet_02_01_01")
        )

        assert_empty @parser.commodities
      end

      # The database names each group of resources under the same form of key
      # the crates use for their own type labels.
      test "#commodities keeps the name of a group of resources out of the catalogue" do
        translate("items_commodities_type_metal" => "Metal")
        resource_types(
          resource_group("Metal", display_name: "@items_commodities_type_metal")
        )

        assert_empty @parser.commodities
      end

      # A resource says nothing about its own type. The group it is filed under
      # is what says what it is, under the same key a crate declares.
      test "#commodities types a resource by the group it is filed under" do
        translate(
          "items_commodities_shipammo_size_1" => "Ship Ammunition - Size 1",
          "items_commodities_type_manmade" => "Man-made"
        )
        resource_types(
          resource_type("ShipAmmoSize1", display_name: "@items_commodities_shipammo_size_1", ref: AMMUNITION_REF),
          resource_group("Bulk_Supplies", display_name: "@items_commodities_type_manmade", members: [AMMUNITION_REF])
        )

        commodity = @parser.commodities.first

        assert_equal "manmade", commodity[:commodity_type]
        assert_equal "Man-made", commodity[:commodity_type_name]
      end

      # Both ore groups carry a placeholder where their label belongs, so an ore
      # read from the database alone would be the only untyped commodity in the
      # catalogue. The material it refines into is filed under a group that is
      # named, and is where the crated ores land too.
      test "#commodities types an unrefined ore after the material it refines into" do
        translate(
          "items_commodities_tin_ore" => "Tin (Ore)",
          "items_commodities_tin" => "Tin",
          "items_commodities_type_metal" => "Metal"
        )
        resource_types(
          resource_type("Ore_Tin", display_name: "@items_commodities_tin_ore", ref: ORE_REF, refined_version: METAL_REF),
          resource_type("Tin", display_name: "@items_commodities_tin", ref: METAL_REF),
          resource_group("UnrefinedOres", display_name: "@LOC_PLACEHOLDER", members: [ORE_REF]),
          resource_group("Metal", display_name: "@items_commodities_type_metal", members: [METAL_REF])
        )

        ore = @parser.commodities.find { |commodity| commodity[:sc_key] == "items_commodities_tin_ore" }

        assert_equal "metal", ore[:commodity_type]
      end

      test "#commodities skips a resource that declares no container to haul it in" do
        translate("items_commodities_oxygen" => "Oxygen")
        resource_types(
          resource_type("Oxygen", display_name: "@items_commodities_oxygen", containers: false)
        )

        assert_empty @parser.commodities
      end

      # The database types a resource by the group it belongs to, which is broader
      # than what the crate declares, so reading it over the crate would cost the
      # commodity the more precise of the two.
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

      # A gem is picked up a piece at a time and each piece rolls its own
      # quality, which is the same fact as the game counting them: a recipe
      # asks for 170 of them rather than for a volume.
      test "#commodities marks a commodity whose container rolls a quality per piece as counted" do
        translate("items_commodities_hadanite" => "Hadanite")
        carryable(
          "1h/harvestable_mineral_1h_hadanite",
          attach_name: "@items_commodities_hadanite",
          display_name: "@items_commodities_hadanite",
          counted: true
        )

        assert @parser.commodities.first[:counted]
      end

      test "#commodities leaves a crate that rolls one quality for the whole container uncounted" do
        translate("items_commodities_iron" => "Iron")
        carryable(
          "2h/carryable_2h_8scu_commodity_metal_iron",
          attach_name: "@items_commodities_iron",
          display_name: "@items_commodities_iron",
          counted: false
        )

        assert_not @parser.commodities.first[:counted]
      end

      # The conversion between the two units a recipe and an inventory speak.
      # Read off the counted container and no other: the same commodity is also
      # sold in crates of 1 to 32 SCU, each declaring its own capacity.
      test "#commodities reads what one piece of a counted commodity takes up" do
        translate("items_commodities_hadanite" => "Hadanite")
        carryable(
          "1h/harvestable_mineral_1h_hadanite",
          attach_name: "@items_commodities_hadanite",
          display_name: "@items_commodities_hadanite",
          counted: true
        )
        carryable(
          "2h/carryable_2h_8scu_commodity_mineral_hadanite",
          attach_name: "@items_commodities_hadanite",
          display_name: "@items_commodities_hadanite",
          counted: false,
          capacity: %(<SStandardCargoUnit standardCargoUnits="8" />)
        )

        assert_in_delta 0.001, @parser.commodities.first[:piece_volume]
      end

      # A crate is sold in seven sizes and the game states each one's capacity,
      # so there is no single figure a bulk commodity could carry.
      test "#commodities leaves a bulk commodity without a piece volume" do
        translate("items_commodities_iron" => "Iron")
        carryable(
          "2h/carryable_2h_8scu_commodity_metal_iron",
          attach_name: "@items_commodities_iron",
          display_name: "@items_commodities_iron",
          counted: false,
          capacity: %(<SStandardCargoUnit standardCargoUnits="8" />)
        )

        assert_nil @parser.commodities.first[:piece_volume]
      end

      # Bulk is the default, so a commodity with no container to read -- the
      # refuel and rearm goods, which no crate entity declares -- is bulk
      # rather than unanswered.
      test "#commodities leaves a resource no crate declares uncounted" do
        translate("items_commodities_shipammo_size_1" => "Ship Ammunition - Size 1")
        resource_types(
          resource_type("ShipAmmoSize1", display_name: "@items_commodities_shipammo_size_1")
        )

        assert_not @parser.commodities.first[:counted]
      end

      # The entity says so by carrying the params at all. What is inside them
      # describes the animation and the packaging, and every commodity that has
      # them agrees on all of it.
      test "#commodities marks a commodity a player can eat or drink" do
        translate("items_commodities_bluebilva" => "Blue Bilva")
        carryable(
          "1h/harvestable_bluebilva",
          attach_name: "@items_commodities_bluebilva",
          display_name: "@items_commodities_bluebilva",
          consumable: true
        )

        assert @parser.commodities.first[:consumable]
      end

      test "#commodities leaves a commodity nothing can be done with uncounted and inedible" do
        translate("items_commodities_iron" => "Iron")
        carryable(
          "2h/carryable_2h_8scu_commodity_metal_iron",
          attach_name: "@items_commodities_iron",
          display_name: "@items_commodities_iron",
          counted: false,
          capacity: %(<SStandardCargoUnit standardCargoUnits="8" />)
        )

        commodity = @parser.commodities.first

        assert_not commodity[:consumable]
        assert_not commodity[:counted]
      end

      # One entity per size, each declaring its own capacity, so the answer is
      # the union over all of them -- sorted, because it is a set and a stable
      # order is what keeps a build comparison from reporting a reshuffle.
      test "#commodities collects every size a commodity is packaged in" do
        translate("items_commodities_gold" => "Gold")
        [8, 1, 32].each do |size|
          carryable(
            "2h/carryable_2h_#{size}scu_commodity_metal_gold",
            attach_name: "@items_commodities_gold",
            display_name: "@items_commodities_gold",
            counted: false,
            capacity: %(<SStandardCargoUnit standardCargoUnits="#{size}" />)
          )
        end

        assert_equal [1.0, 8.0, 32.0], @parser.commodities.first[:container_sizes]
      end

      # A loose gem is not a container you can put it in. Nineteen of the
      # counted commodities have nothing else, and come out with no container
      # at all -- which is the true answer: you carry them, or you leave them.
      test "#commodities keeps the loose piece out of the containers it hauls in" do
        translate("items_commodities_hadanite" => "Hadanite")
        carryable(
          "1h/harvestable_mineral_1h_hadanite",
          attach_name: "@items_commodities_hadanite",
          display_name: "@items_commodities_hadanite",
          counted: true
        )
        carryable(
          "2h/carryable_2h_8scu_commodity_mineral_hadanite",
          attach_name: "@items_commodities_hadanite",
          display_name: "@items_commodities_hadanite",
          counted: false,
          capacity: %(<SStandardCargoUnit standardCargoUnits="8" />)
        )

        commodity = @parser.commodities.first

        assert_in_delta 0.001, commodity[:piece_volume]
        assert_equal [8.0], commodity[:container_sizes]
      end

      test "#commodities leaves a commodity carried only loose without any container" do
        translate("items_commodities_amiantpod" => "Amiant Pod")
        carryable(
          "1h/harvestable_amiantpod",
          attach_name: "@items_commodities_amiantpod",
          display_name: "@items_commodities_amiantpod",
          counted: true
        )

        assert_empty @parser.commodities.first[:container_sizes]
      end

      # Both ends of the link are references into the resource database, so
      # neither can be named until the other is resolved.
      test "#commodities names the good an ore refines into" do
        translate(
          "items_commodities_tin_ore" => "Tin (Ore)",
          "items_commodities_tin" => "Tin"
        )
        resource_types(
          resource_type("Ore_Tin", display_name: "@items_commodities_tin_ore", ref: ORE_REF, refined_version: METAL_REF),
          resource_type("Tin", display_name: "@items_commodities_tin", ref: METAL_REF)
        )

        ore = @parser.commodities.find { |commodity| commodity[:sc_key] == "items_commodities_tin_ore" }
        refined = @parser.commodities.find { |commodity| commodity[:sc_key] == "items_commodities_tin" }

        assert_equal "items_commodities_tin", ore[:refines_into]
        assert_nil refined[:refines_into]
      end

      private def resource_type(name, display_name:, ref: nil, refined_version: nil, containers: true)
        record(
          "ResourceType.#{name}",
          {displayName: display_name, __ref: ref, refinedVersion: refined_version, __type: "ResourceType"},
          (containers_xml if containers)
        )
      end

      private def resource_group(name, display_name:, members: [])
        record(
          "ResourceTypeGroup.#{name}",
          {displayName: display_name, __type: "ResourceTypeGroup"},
          references_xml(members)
        )
      end

      private def record(tag, attributes, children)
        listed = attributes.compact.map { |name, value| %(#{name}="#{value}") }.join(" ")

        <<~XML
          <#{tag} #{listed}>
            #{children}
          </#{tag}>
        XML
      end

      private def containers_xml
        %(<defaultCargoContainers><SResourceTypeDefaultCargoContainers oneSCU="beef" /></defaultCargoContainers>)
      end

      private def references_xml(refs)
        return if refs.empty?

        "<resources>#{refs.map { |ref| %(<Reference value="#{ref}" />) }.join}</resources>"
      end

      private def resource_types(*records)
        target = "#{@raw_path}/#{RECORDS_PATH}/#{::ScData::Parser::CommoditiesParser::RESOURCE_TYPES_PATH}"

        FileUtils.mkdir_p(File.dirname(target))

        File.write(target, "<Records>\n#{records.join}</Records>\n")
      end

      private def translate(entries)
        @parser.translations = entries
      end

      private def carryable(path, attach_name:, display_name:, display_type: "@LOC_PLACEHOLDER", counted: nil,
        capacity: %(<SMicroCargoUnit microSCU="1000" />), consumable: false)
        write_record(
          "entities/scitem/carryables/#{path}",
          <<~XML
            <SCItemPurchasableParams displayName="#{display_name}" displayType="#{display_type}" />
            #{consumable_xml(consumable)}
            #{resource_container_xml(counted, capacity)}
            <SAttachableComponentParams attachToTileItemPort="NoConnection">
              <AttachDef Type="Cargo" SubType="Cargo">
                <Localization Name="#{attach_name}" ShortName="@LOC_EMPTY" Description="@LOC_EMPTY" />
              </AttachDef>
            </SAttachableComponentParams>
          XML
        )
      end

      private def consumable_xml(consumable)
        %(<SCItemConsumableParams containerTypeTag="fruit" discardWhenConsumed="1" />) if consumable
      end

      private def resource_container_xml(counted, capacity)
        return if counted.nil?

        <<~XML
          <ResourceContainer mutabilityLevel="ReadOnly" generateRandomQuality="#{counted ? 1 : 0}">
            <capacity>#{capacity}</capacity>
          </ResourceContainer>
        XML
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
