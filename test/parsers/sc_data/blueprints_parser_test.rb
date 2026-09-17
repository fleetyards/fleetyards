# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class BlueprintsParserTest < ActiveSupport::TestCase
      RECORDS_PATH = "Data/Libs/Foundry/Records"

      IRON_REF = "f386a33c-ac9a-400a-a7b8-fe1fc7c8d270"
      APHORITE_REF = "3f137385-dd8f-410b-b5f3-7b4d283c09cd"
      DAMAGE_REF = "cfc129ce-488a-46f2-92f7-9272cd0cfdfb"
      OUTPUT_REF = "75809555-848a-4f4d-81a0-db4457edba2d"

      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"

        FileUtils.mkdir_p("#{@raw_path}/Data/Localization/english")
        File.write("#{@raw_path}/Data/Localization/english/global.ini", "")

        @parser = ::ScData::Parser::BlueprintsParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      test "#blueprints reads the recipe, its slots and what it makes" do
        translate(
          "crafting_ui_slotname_frame" => "Frame",
          "item_Name_klwe_smg_energy_01" => "Yubarev Pistol"
        )
        resource_types(resource_type("Iron", ref: IRON_REF, display_name: "@items_commodities_iron"))
        entity("entities/scitem/weapons/fps_weapons/klwe_smg_energy_01",
          ref: OUTPUT_REF, attach_name: "@item_Name_klwe_smg_energy_01")
        blueprint("fpsgear/weapons/smg/bp_craft_klwe_smg_energy_01", count: 3, seconds: 120)

        parsed = @parser.blueprints

        assert_equal 1, parsed.size

        recipe = parsed.first

        assert_equal "bp_craft_klwe_smg_energy_01", recipe[:key]
        assert_equal 120, recipe[:craft_time]
        assert_equal 3, recipe[:slot_count]
        assert_equal "Yubarev Pistol", recipe.dig(:output, :name)
        assert_equal "Equipment", recipe.dig(:output, :kind)
        assert_equal 1, recipe[:slots].size
      end

      # Every `@crafting_ui_slotname_*` key in 4.10.1 is declared with a ",P"
      # plural marker, and every `@StatName_GPP_*` in another case. An exact
      # lookup -- which is what `translate` does -- returns nothing for all 73
      # slots and 24 of the 29 stats, and the ramps would ship unlabelled.
      test "#blueprints resolves slot and stat names declared with a plural marker" do
        translate(
          "crafting_ui_slotname_frame,P" => "Frame",
          "StatName_GPP_Weapon_Damage,P" => "Impact Force"
        )
        crafted_property("GPP_Weapon_Damage", ref: DAMAGE_REF, property_name: "@StatName_GPP_Weapon_Damage")
        resource_types(resource_type("Iron", ref: IRON_REF, display_name: "@items_commodities_iron"))
        blueprint("fpsgear/weapons/smg/bp_craft_example", modifiers: [{ref: DAMAGE_REF}])

        slot = @parser.blueprints.first[:slots].first

        assert_equal "Frame", slot[:name]
        assert_equal "frame", slot[:key]
        assert_equal "Impact Force", slot[:modifiers].first[:name]
        assert_equal "gpp_weapon_damage", slot[:modifiers].first[:property_key]
      end

      # The cost names a ResourceType GUID, and `Commodity#sc_ref` is null for
      # 100 of the 232 rows -- Iron included -- so the only join that works goes
      # through the `@items_commodities_*` key.
      test "#blueprints resolves a resource cost to its commodity key" do
        resource_types(resource_type("Iron", ref: IRON_REF, display_name: "@items_commodities_iron"))
        blueprint("fpsgear/weapons/smg/bp_craft_example", resource: IRON_REF, quantity: "0.03")

        option = @parser.blueprints.first[:slots].first[:options].first

        assert_equal "resource", option[:cost_type]
        assert_equal "items_commodities_iron", option[:commodity_key]
        assert_in_delta 0.03, option[:quantity]
        assert_equal 0, option[:position]
      end

      # A hand-carried harvestable is named as an entity rather than as a
      # resource, and is counted in whole pieces rather than in SCU.
      test "#blueprints resolves an item cost through the carryable it names" do
        translate("items_commodities_aphorite" => "Aphorite")
        entity("entities/scitem/carryables/1h/harvestable_mineral_1h_aphorite",
          ref: APHORITE_REF, attach_name: "@items_commodities_aphorite")
        blueprint("fpsgear/weapons/smg/bp_craft_example", item: APHORITE_REF, quantity: "2")

        option = @parser.blueprints.first[:slots].first[:options].first

        assert_equal "item", option[:cost_type]
        assert_equal "items_commodities_aphorite", option[:commodity_key]
        assert_in_delta 2.0, option[:quantity]
      end

      # A ship gun lives under `entities/scitem/ships/weapons`. Matching the
      # weapons tree first would file 125 turret and gun records as something a
      # player wears.
      test "#blueprints files a ship gun as a component rather than as equipment" do
        entity("entities/scitem/ships/weapons/behr_laser_cannon_s1", ref: OUTPUT_REF, attach_name: "@LOC_EMPTY")
        blueprint("vehiclegear/weapons/bp_craft_behr_laser_cannon_s1")

        assert_equal "Component", @parser.blueprints.first.dig(:output, :kind)
      end

      # `bp_craft_cool_s04_cnou_pioneer` names an entity class that is in no
      # file in the export. It has to survive as a ref so the loader can count
      # it, rather than taking the parse down or vanishing.
      test "#blueprints keeps a recipe whose output resolves to nothing" do
        blueprint("vehiclegear/cooler/bp_craft_cool_s04_cnou_pioneer")

        output = @parser.blueprints.first[:output]

        assert_equal OUTPUT_REF, output[:ref]
        assert_nil output[:kind]
        assert_nil output[:name]
      end

      # 1007 slots ramp a stat piecewise -- 0.95 to 1.0 across quality 0-499,
      # then 1.0 to 1.05 across 500-1000 -- so a reader that takes one range per
      # stat reports half the gain.
      test "#blueprints keeps every segment of a piecewise ramp" do
        translate("StatName_GPP_Weapon_Damage" => "Impact Force")
        crafted_property("GPP_Weapon_Damage", ref: DAMAGE_REF, property_name: "@StatName_GPP_Weapon_Damage")
        blueprint("fpsgear/weapons/smg/bp_craft_example", modifiers: [
          {ref: DAMAGE_REF, ranges: [
            {start_quality: 0, end_quality: 499, at_start: "0.95", at_end: "1.0"},
            {start_quality: 500, end_quality: 1000, at_start: "1.0", at_end: "1.05"}
          ]}
        ])

        modifiers = @parser.blueprints.first[:slots].first[:modifiers]

        assert_equal 2, modifiers.size
        assert_equal [0, 1], modifiers.pluck(:position)
        assert_equal [499, 1000], modifiers.pluck(:end_quality)
        assert_equal ["linear", "linear"], modifiers.pluck(:ramp)
      end

      test "#blueprints tells an additive ramp from a scaling one" do
        crafted_property("GPP_Weapon_Damage", ref: DAMAGE_REF, property_name: "@StatName_GPP_Weapon_Damage")
        blueprint("fpsgear/weapons/smg/bp_craft_example", modifiers: [
          {ref: DAMAGE_REF, type: "CraftingGameplayPropertyModifierValueRange_LinearIntegerAdditive"}
        ])

        assert_equal(
          ["linear_integer_additive"],
          @parser.blueprints.first[:slots].first[:modifiers].pluck(:ramp)
        )
      end

      test "#blueprints skips a record carrying no mandatory cost" do
        write("crafting/blueprints/crafting/fpsgear/bp_craft_empty", <<~XML)
          <blueprint>
            <CraftingBlueprint category="beef" blueprintName="@LOC_PLACEHOLDER" />
          </blueprint>
        XML

        assert_empty @parser.blueprints
      end

      private def translate(entries)
        @parser.translations = entries
      end

      private def blueprint(path, count: 1, seconds: 10, resource: nil, item: nil,
        quantity: "0.03", modifiers: [])
        cost = if item.present?
          %(<CraftingCost_Item entityClass="#{item}" quantity="#{quantity}" minQuality="0" />)
        else
          <<~XML
            <CraftingCost_Resource resource="#{resource || IRON_REF}" minQuality="0">
              <quantity><SStandardCargoUnit standardCargoUnits="#{quantity}" /></quantity>
            </CraftingCost_Resource>
          XML
        end

        write("crafting/blueprints/crafting/#{path}", <<~XML)
          <blueprint>
            <CraftingBlueprint category="beef" blueprintName="@LOC_PLACEHOLDER">
              <processSpecificData>
                <CraftingProcess_Creation entityClass="#{OUTPUT_REF}" />
              </processSpecificData>
              <tiers>
                <CraftingBlueprintTier>
                  <recipe>
                    <CraftingRecipe>
                      <costs>
                        <CraftingRecipeCosts>
                          <craftTime>
                            <TimeValue_Partitioned days="0" hours="0" minutes="0" seconds="#{seconds}" />
                          </craftTime>
                          <mandatoryCost>
                            <CraftingCost_Select count="#{count}">
                              <nameInfo debugName="ASPECTS" displayName="@LOC_PLACEHOLDER" />
                              <options>
                                <CraftingCost_Select count="1">
                                  #{modifiers_xml(modifiers)}
                                  <nameInfo debugName="FRAME" displayName="@crafting_ui_slotname_frame" />
                                  <options>#{cost}</options>
                                </CraftingCost_Select>
                              </options>
                            </CraftingCost_Select>
                          </mandatoryCost>
                        </CraftingRecipeCosts>
                      </costs>
                    </CraftingRecipe>
                  </recipe>
                </CraftingBlueprintTier>
              </tiers>
            </CraftingBlueprint>
          </blueprint>
        XML
      end

      private def modifiers_xml(modifiers)
        return if modifiers.blank?

        listed = modifiers.map do |modifier|
          type = modifier[:type] || "CraftingGameplayPropertyModifierValueRange_Linear"
          ranges = modifier[:ranges] || [{start_quality: 0, end_quality: 1000, at_start: "0.9", at_end: "1.1"}]

          <<~XML
            <CraftingGameplayPropertyModifierCommon gameplayPropertyRecord="#{modifier[:ref]}">
              <valueRanges>
                #{ranges.map { |range| range_xml(type, range) }.join}
              </valueRanges>
            </CraftingGameplayPropertyModifierCommon>
          XML
        end

        <<~XML
          <context>
            <CraftingCostContext_ResultGameplayPropertyModifiers>
              <gameplayPropertyModifiers>
                <CraftingGameplayPropertyModifiers_List>
                  <gameplayPropertyModifiers>#{listed.join}</gameplayPropertyModifiers>
                </CraftingGameplayPropertyModifiers_List>
              </gameplayPropertyModifiers>
            </CraftingCostContext_ResultGameplayPropertyModifiers>
          </context>
        XML
      end

      private def range_xml(type, range)
        %(<#{type} startQuality="#{range[:start_quality]}" endQuality="#{range[:end_quality]}" ) +
          %(modifierAtStart="#{range[:at_start]}" modifierAtEnd="#{range[:at_end]}" />)
      end

      private def crafted_property(name, ref:, property_name:, unit: "@LOC_EMPTY")
        target = "#{@raw_path}/#{RECORDS_PATH}/crafting/craftedproperties/#{name.downcase}.xml"

        FileUtils.mkdir_p(File.dirname(target))

        File.write(target, <<~XML)
          <CraftingGameplayPropertyDef.#{name} propertyName="#{property_name}" unitFormat="#{unit}"
            __type="CraftingGameplayPropertyDef" __ref="#{ref}" />
        XML
      end

      private def resource_type(name, ref:, display_name:)
        %(<ResourceType.#{name} displayName="#{display_name}" __type="ResourceType" __ref="#{ref}" />)
      end

      private def resource_types(*records)
        target = "#{@raw_path}/#{RECORDS_PATH}/#{::ScData::Parser::BlueprintsParser::RESOURCE_TYPES_PATH}"

        FileUtils.mkdir_p(File.dirname(target))

        File.write(target, "<Records>\n#{records.join}\n</Records>\n")
      end

      private def entity(path, ref:, attach_name:)
        write(path, <<~XML, ref:)
          <Components>
            <SAttachableComponentParams attachToTileItemPort="NoConnection">
              <AttachDef Type="Cargo" SubType="Cargo">
                <Localization Name="#{attach_name}" ShortName="@LOC_EMPTY" Description="@LOC_EMPTY" />
              </AttachDef>
            </SAttachableComponentParams>
          </Components>
        XML
      end

      private def write(path, body, ref: nil)
        target = "#{@raw_path}/#{RECORDS_PATH}/#{path}.xml"
        tag = File.basename(path)

        FileUtils.mkdir_p(File.dirname(target))

        File.write(target, <<~XML)
          <Record.#{tag} __ref="#{ref || record_ref(path)}">
            #{body}
          </Record.#{tag}>
        XML
      end

      private def record_ref(path)
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, path)
      end
    end
  end
end
