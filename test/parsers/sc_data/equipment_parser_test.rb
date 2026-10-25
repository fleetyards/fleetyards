# frozen_string_literal: true

require "test_helper"
require "tmpdir"

# `parse_equipment` returns early on a blank name, so a key the export declares
# in a spelling `translate` cannot match does not load nameless -- it does not
# load at all. 84 records were missing from the catalogue for that reason.
module ScData
  module Parser
    class EquipmentParserTest < ActiveSupport::TestCase
      SOURCE_PATH = "entities/scitem/characters/human/clothing"

      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"

        FileUtils.mkdir_p("#{@raw_path}/Data/Localization/english")
        File.write("#{@raw_path}/Data/Localization/english/global.ini", "")

        write_equipment("hdh_boots_01_01_13", name: "@item_Name_hdh_boots_01_01_13")

        @parser = ::ScData::Parser::EquipmentParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      test "loads a record whose name the export declares with a plural marker" do
        @parser.translations = {"item_Name_hdh_boots_01_01_13,P" => "Novian \"Nighthunter\" Boots"}

        assert_equal "Novian \"Nighthunter\" Boots", parsed.fetch("hdh_boots_01_01_13")["name"]
      end

      test "loads a record whose name the export declares in another case" do
        @parser.translations = {"item_name_hdh_boots_01_01_13" => "P4-AR \"Star Kitten\" Rifle"}

        assert_equal "P4-AR \"Star Kitten\" Rifle", parsed.fetch("hdh_boots_01_01_13")["name"]
      end

      test "leaves out a record the export has not named at all" do
        @parser.translations = {}

        assert_empty parsed
      end

      # 25 of the records the index unlocks are named "PH - hdh_boots_01_01_13"
      # or "PLACEHOLDER - SPV Jacket". They are better left where they are.
      test "leaves out a record whose name the export marks as a placeholder" do
        @parser.translations = {"item_Name_hdh_boots_01_01_13,P" => "PH - hdh_boots_01_01_13"}

        assert_empty parsed
      end

      # A tint is a colourway a player can own, with a name of its own, so it is
      # listed as a version of its base rather than hidden.
      test "keeps a tint visible as a version of its base" do
        write_equipment("mrai_flightsuit_01_07", name: "@item_Name_mrai_flightsuit_01_07")
        write_equipment("mrai_flightsuit_01_07_tint02", name: "@item_Name_mrai_flightsuit_01_07_tint02")

        @parser.translations = {
          "item_Name_hdh_boots_01_01_13,P" => "Novian \"Nighthunter\" Boots",
          "item_Name_mrai_flightsuit_01_07" => "Neutrino Racing Flight Suit",
          "item_Name_mrai_flightsuit_01_07_tint02,P" => "Neutrino Racing Flight Suit WhiteHot"
        }

        assert_not parsed.fetch("mrai_flightsuit_01_07_tint02")["hidden"]
        assert_equal %w[mrai_flightsuit_01_07 mrai_flightsuit_01_07],
          parsed.values_at("mrai_flightsuit_01_07", "mrai_flightsuit_01_07_tint02").pluck("family_key")
      end

      test "files a weapon skin under its base weapon but not the weapon's magazine" do
        write_weapon("klwe_rifle_energy_01", "Gallant Rifle")
        write_weapon("klwe_rifle_energy_01_white02", "Gallant \"Boneyard\" Rifle")
        write_weapon("klwe_rifle_energy_01_white02_tow", "Gallant \"Boneyard\" Rifle")
        write_attachment("klwe_rifle_energy_01_mag", "Gallant Rifle Battery", sub_type: "Magazine")

        assert_equal ["klwe_rifle_energy_01"] * 3,
          parsed.values_at("klwe_rifle_energy_01", "klwe_rifle_energy_01_white02", "klwe_rifle_energy_01_white02_tow")
            .pluck("family_key")
        assert_nil parsed.fetch("klwe_rifle_energy_01_mag")["family_key"]
      end

      # Worn colourways have no base record to extend, so they share the key
      # without its colour instead.
      test "files worn colourways under their shared key" do
        write_equipment("hdh_boots_01_01_14", name: "@item_Name_hdh_boots_01_01_14")
        write_equipment("hdh_hat_01_01_01", name: "@item_Name_hdh_hat_01_01_01", type: "Char_Clothing_Hat")

        @parser.translations = {
          "item_Name_hdh_boots_01_01_13" => "Novian Boots Black",
          "item_Name_hdh_boots_01_01_14" => "Novian Boots Red",
          "item_Name_hdh_hat_01_01_01" => "Novian Hat"
        }

        assert_equal %w[hdh_boots_01_01 hdh_boots_01_01],
          parsed.values_at("hdh_boots_01_01_13", "hdh_boots_01_01_14").pluck("family_key")
        assert_nil parsed.fetch("hdh_hat_01_01_01")["family_key"]
      end

      test "reads glasses as eyewear" do
        write_equipment("r6p_glasses_01_01_01", name: "@item_Name_r6p_glasses_01_01_01",
          path: "entities/scitem/characters/human/head/npc/eyes/accessories", type: "Char_Accessory_Eyes")
        @parser.translations = {"item_Name_r6p_glasses_01_01_01" => "Yaeger Aviator Glasses"}

        assert_equal %w[clothing eyewear], parsed.fetch("r6p_glasses_01_01_01").values_at("equipment_type", "slot")
      end

      test "reads a garment past the outfit line or faction its key names first" do
        {
          "cba_chef_jacket_01_01_01" => "Char_Clothing_Torso_1",
          "spv_bioticorp_rep_heels_01_01_01" => "Char_Clothing_Feet",
          "sc_nvy_bdu_trouser_01_01_01" => "Char_Clothing_Legs",
          "mannequin_displaycore" => "Char_Armor_Torso"
        }.each do |key, type|
          write_equipment(key, name: "@item_Name_#{key}", type:)
        end
        @parser.translations = {
          "item_Name_cba_chef_jacket_01_01_01" => "Grammercy Food Service Jacket",
          "item_Name_spv_bioticorp_rep_heels_01_01_01" => "Dovo Shoes",
          "item_Name_sc_nvy_bdu_trouser_01_01_01" => "Combat Readiness Uniform Trousers",
          "item_Name_mannequin_displaycore" => "Display Core"
        }

        assert_equal "jacket", parsed.fetch("cba_chef_jacket_01_01_01")["item_type"]
        assert_equal "shoes", parsed.fetch("spv_bioticorp_rep_heels_01_01_01")["item_type"]
        assert_equal "pants", parsed.fetch("sc_nvy_bdu_trouser_01_01_01")["item_type"]
        assert_nil parsed.fetch("mannequin_displaycore")["item_type"]
      end

      test "reads a garment whose header rates it as armour as the garment" do
        write_equipment("thp_jacket_01_01_01", name: "@item_Name_thp_jacket_01_01_01",
          type: "Char_Clothing_Torso_1", description: "@item_Desc_thp_jacket_01_01_01")
        @parser.translations = {
          "item_Name_thp_jacket_01_01_01" => "Field Jacket",
          "item_Desc_thp_jacket_01_01_01" => "Item Type: Heavy Armor\\n\\nWarm."
        }

        assert_equal %w[clothing jacket], parsed.fetch("thp_jacket_01_01_01").values_at("equipment_type", "item_type")
      end

      test "reads undescribed armour by the weight its key names, as the described armour reads" do
        {
          "kap_combat_heavy_arms_02_03_01" => "Char_Armor_Arms",
          "kap_combat_heavy_backpack_01_01_10" => "Char_Armor_Backpack",
          "mrai_flightsuit_helmet_01_01_01" => "Char_Armor_Helmet",
          "mrai_flightsuit_light_arms_01_01_01" => "Char_Armor_Arms",
          "mrai_flightsuit_01_01_01" => "Char_Armor_Undersuit",
          "nvy_pilot_undersuit_01_01_01" => "Char_Armor_Undersuit"
        }.each do |key, type|
          write_equipment(key, name: "@item_Name_#{key}", path: "entities/scitem/characters/human/armor", type:)
        end
        @parser.translations = {
          "item_Name_kap_combat_heavy_arms_02_03_01" => "Monde Arms",
          "item_Name_kap_combat_heavy_backpack_01_01_10" => "Monde Backpack",
          "item_Name_mrai_flightsuit_helmet_01_01_01" => "Neutrino Racing Helmet",
          "item_Name_mrai_flightsuit_light_arms_01_01_01" => "Neutrino Racing Arms",
          "item_Name_mrai_flightsuit_01_01_01" => "Neutrino Racing Flight Suit",
          "item_Name_nvy_pilot_undersuit_01_01_01" => "OMNI-CFS-Diamond Flight Suit"
        }

        assert_equal "heavy_armor", parsed.fetch("kap_combat_heavy_arms_02_03_01")["item_type"]
        assert_equal "heavy_backpack", parsed.fetch("kap_combat_heavy_backpack_01_01_10")["item_type"]
        assert_equal "flight_helmet", parsed.fetch("mrai_flightsuit_helmet_01_01_01")["item_type"]
        assert_equal "light_armor", parsed.fetch("mrai_flightsuit_light_arms_01_01_01")["item_type"]
        assert_equal "flight_suit", parsed.fetch("mrai_flightsuit_01_01_01")["item_type"]
        assert_equal "undersuit", parsed.fetch("nvy_pilot_undersuit_01_01_01")["item_type"]
      end

      test "reads a weapon mount's class past the mount and a short grenade key as a grenade" do
        write_equipment("weaponmount_nvtc_optics_holo_x1_s1", name: "@item_Name_weaponmount_nvtc_optics_holo_x1_s1",
          path: "entities/scitem/weapons/weapon_modifier", type: "WeaponAttachment")
        write_equipment("ksar_gren_frag_01", name: "@item_Name_ksar_gren_frag_01",
          path: "entities/scitem/weapons/throwable", type: "Grenade")
        @parser.translations = {
          "item_Name_weaponmount_nvtc_optics_holo_x1_s1" => "Gamma (1x Holographic)",
          "item_Name_ksar_gren_frag_01" => "Scorch Plasma Grenade"
        }

        assert_equal "weapon_scope", parsed.fetch("weaponmount_nvtc_optics_holo_x1_s1")["item_type"]
        assert_equal "grenade", parsed.fetch("ksar_gren_frag_01")["item_type"]
      end

      test "files the hand-held gadgets the game calls weapons as tools" do
        write_equipment("grin_multitool_01", name: "@item_Name_grin_multitool_01",
          path: "entities/scitem/weapons/fps_weapons", type: "WeaponPersonal", sub_type: "Gadget")
        write_equipment("crlf_medgun_01", name: "@item_Name_crlf_medgun_01",
          path: "entities/scitem/weapons/fps_weapons", type: "WeaponPersonal", sub_type: "Small",
          description: "@item_Desc_crlf_medgun_01")
        write_equipment("crlf_medgun_02", name: "@item_Name_crlf_medgun_02",
          path: "entities/scitem/weapons/fps_weapons", type: "WeaponPersonal", sub_type: "Small")
        write_equipment("behr_ltp_kinetic_01", name: "@item_Name_behr_ltp_kinetic_01",
          path: "entities/scitem/weapons/fps_weapons", type: "WeaponPersonal", sub_type: "Small")
        @parser.translations = {
          "item_Name_grin_multitool_01" => "Pyro RYT Multi-Tool",
          "item_Name_crlf_medgun_01" => "ParaMed Medical Device",
          "item_Desc_crlf_medgun_01" => "Item Type: Medical Device\\n\\nHeals.",
          "item_Name_crlf_medgun_02" => "LifeGuard Medical Device",
          "item_Name_behr_ltp_kinetic_01" => "ADO-5 Laser Mine"
        }

        assert_equal %w[tool multitool], parsed.fetch("grin_multitool_01").values_at("equipment_type", "item_type")
        assert_equal %w[tool medical_device], parsed.fetch("crlf_medgun_01").values_at("equipment_type", "item_type")
        assert_equal %w[tool medical_tool], parsed.fetch("crlf_medgun_02").values_at("equipment_type", "item_type")
        assert_equal %w[weapon mine], parsed.fetch("behr_ltp_kinetic_01").values_at("equipment_type", "item_type")
      end

      test "reads the flares and tool cases among the props by their key" do
        write_equipment("carryable_1h_cu_glowstick_blue", name: "@item_Nameun_portable_light_1_a_cyan",
          path: "entities/scitem/flair/carryables", type: "WeaponPersonal", description: "@item_Desc_flare")
        write_equipment("carryable_2h_fl_container_anim_medgun_1_a", name: "@item_Name_medic_kit",
          path: "entities/scitem/carryables/2h", type: "Misc")
        @parser.translations = {
          "item_Nameun_portable_light_1_a_cyan" => "Cyan QuikFlarePro",
          "item_Desc_flare" => "Item Type: Grenade\\n\\nGlows longer than regular flares.",
          "item_Name_medic_kit" => "Field Medic Kit"
        }

        assert_equal %w[tool flare], parsed.fetch("carryable_1h_cu_glowstick_blue").values_at("equipment_type", "item_type")
        assert_equal %w[tool tool_case],
          parsed.fetch("carryable_2h_fl_container_anim_medgun_1_a").values_at("equipment_type", "item_type")
      end

      test "files the mining gadgets and the flair by their folder" do
        write_equipment("mining_gadget_thcn_boremax", name: "@item_Name_boremax",
          path: "entities/scitem/weapons/devices", type: "Gadget", description: "@item_Desc_boremax")
        write_equipment("flair_model_freelancer", name: "@item_Name_freelancer_model",
          path: "entities/scitem/flair/models", type: "Flair_Surface")
        @parser.translations = {
          "item_Name_boremax" => "BoreMax",
          "item_Desc_boremax" => "Manufacturer: Thermyte Concern\\nItem Type: Mining Gadget\\n\\nKeeps clusters together.",
          "item_Name_freelancer_model" => "Freelancer Model"
        }

        assert_equal %w[mining_gadget mining_gadget],
          parsed.fetch("mining_gadget_thcn_boremax").values_at("equipment_type", "item_type")
        assert_equal ["flair", nil], parsed.fetch("flair_model_freelancer").values_at("equipment_type", "item_type")
      end

      test "types each carryable by what it is" do
        write_carryable("food_burger_wham_01_a", "Whamburger", type: "Food", sub_type: "Junk")
        write_carryable("carryable_tbo_inventorycontainer_8scu", "Stor*All 8 SCU Self-Storage Container",
          type: "InventoryContainer", sub_type: "Cargo", folder: "tractorbeamonly",
          attach_extra: %(<inventoryOccupancyVolume><SStandardCargoUnit standardCargoUnits="8" /></inventoryOccupancyVolume>))
        write_carryable("carryable_1h_cy_flair_poster_ht", "Hull C Poster", sub_type: "Utility")
        write_carryable("bltr_consumable_hackingchip_01", "Tigersclaw", type: "FPS_Consumable", sub_type: "Hacking")
        write_carryable("ori_game_chess_1_king_a", "Origin White King", type: "Gadget")

        assert_equal "sustenance", parsed.fetch("food_burger_wham_01_a")["equipment_type"]
        assert_equal ["container", 8.0],
          parsed.fetch("carryable_tbo_inventorycontainer_8scu").values_at("equipment_type", "volume")
        assert_equal "flair", parsed.fetch("carryable_1h_cy_flair_poster_ht")["equipment_type"]
        assert_equal %w[hacking_tool cryptokey],
          parsed.fetch("bltr_consumable_hackingchip_01").values_at("equipment_type", "item_type")
        assert_equal ["carryable", nil], parsed.fetch("ori_game_chess_1_king_a").values_at("equipment_type", "item_type")
      end

      test "reads the mobiGlas casings and thruster packs from the suit folder, and nothing else there" do
        write_equipment("mobiglas_02", name: "@item_Name_mobiglas_02", path: "entities/scitem/suit", type: "MobiGlas")
        write_equipment("m_slaver_medium_jetpack", name: "@item_Name_fireshot",
          path: "entities/scitem/suit/thrusterpack/slaver", type: "Suit", sub_type: "ThrusterPack")
        write_equipment("rrs_radar_suit", name: "@item_Name_radar", path: "entities/scitem/suit", type: "Radar")
        @parser.translations = {
          "item_Name_hdh_boots_01_01_13" => "Novian \"Nighthunter\" Boots",
          "item_Name_mobiglas_02" => "mobiGlas Crimson Casing",
          "item_Name_fireshot" => "F1M-Fireshot",
          "item_Name_radar" => "Suit Radar"
        }

        assert_equal %w[clothing mobiglas_casing], parsed.fetch("mobiglas_02").values_at("equipment_type", "item_type")
        assert_equal %w[armor thruster_pack],
          parsed.fetch("m_slaver_medium_jetpack").values_at("equipment_type", "item_type")
        assert_not parsed.key?("rrs_radar_suit")
      end

      # Harvestables, SLAM and the commodity crates carry a commodity's name,
      # and the commodities parser loads them from the same records.
      test "leaves out the carryables that are cargo, commodities or mission props" do
        write_carryable("carryable_tbo_fl_16scu_commodity_processedgoods_shipammunition", "Ship Ammunition",
          type: "Cargo", sub_type: "Cargo", folder: "tractorbeamonly")
        write_carryable("harvestable_heart_of_the_woods", "Heart of the Woods", sub_type: "Harvestable",
          components_extra: %(<SCItemPurchasableParams displayName="@items_commodities_heartofthewoods" />))
        write_carryable("carryable_2h_fl_05x05x05_missionitem_pizzabox_1_a", "Pizza Box")
        write_carryable("carryable_1h_sq_datapad_fluff_fffinale", "Datapad")

        assert_equal ["hdh_boots_01_01_13"], parsed.keys
      end

      test "shows one of the same carried prop filed under two keys" do
        write_carryable("plushy_orison_whale_1_a", "Finley the Stormwal Plushie")
        write_carryable("carryable_1h_cy_toy_plushy_orison_whale_1_a", "Finley the Stormwal Plushie", sub_type: "Personal")

        assert_equal [false, true],
          parsed.values_at("carryable_1h_cy_toy_plushy_orison_whale_1_a", "plushy_orison_whale_1_a").pluck("hidden")
      end

      # The Venture Starwalker helmet in 4.10.3 opens its description with a
      # line break.
      test "reads the spec block of a description that opens with a blank line" do
        @parser.translations = {
          "item_Name_hdh_boots_01_01_13" => "Venture Helmet",
          "item_Desc_venture" => '\nItem Type: Light Armor \nDamage Reduction: 20% \n\nA helmet.'
        }
        write_equipment("hdh_boots_01_01_13", name: "@item_Name_hdh_boots_01_01_13", description: "@item_Desc_venture")

        record = parsed.fetch("hdh_boots_01_01_13")

        assert_equal "A helmet.", record["description"]
        assert_equal "20.0", record["damage_reduction"]
      end

      # Memoized: a second `all` on the same parser writes over a folder
      # `clear_once` has already swept, which the parser reports as a duplicate.
      private def parsed
        @parsed ||= begin
          @parser.all

          Dir.glob("#{@base_folder}/parsed/test/equipment/*.json").to_h do |file|
            [File.basename(file, ".json"), JSON.parse(File.read(file))]
          end
        end
      end

      private def write_carryable(key, display_name, type: "Misc", sub_type: "UNDEFINED", folder: "1h", **)
        write_equipment(key, name: "@item_Name_#{key}", path: "entities/scitem/carryables/#{folder}", type:, sub_type:, **)
        name_record(key, display_name)
      end

      private def write_weapon(key, display_name, **)
        write_equipment(key, name: "@item_Name_#{key}", path: "entities/scitem/weapons/fps_weapons",
          type: "WeaponPersonal", sub_type: "Medium", **)
        name_record(key, display_name)
      end

      private def write_attachment(key, display_name, sub_type:)
        write_equipment(key, name: "@item_Name_#{key}", path: "entities/scitem/weapons/magazines",
          type: "WeaponAttachment", sub_type:)
        name_record(key, display_name)
      end

      private def name_record(key, display_name)
        @parser.translations = (@parser.translations || {}).merge(
          "item_Name_hdh_boots_01_01_13" => "Novian \"Nighthunter\" Boots",
          "item_Name_#{key}" => display_name
        )
      end

      private def write_equipment(key, name:, path: SOURCE_PATH, type: "Char_Clothing_Feet", sub_type: "UNDEFINED",
        description: "@LOC_EMPTY", attach_extra: "", components_extra: "")
        folder = "#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/#{path}"

        FileUtils.mkdir_p(folder)

        File.write("#{folder}/#{key}.xml", <<~XML)
          <EntityClassDefinition.#{key} __ref="00000000-0000-0000-0000-00000000beef">
            <Components>
              <SAttachableComponentParams>
                <AttachDef Type="#{type}" SubType="#{sub_type}" Size="1" Grade="1" Tags="#{key}">
                  <Localization Name="#{name}" ShortName="@LOC_EMPTY" Description="#{description}" />
                  #{attach_extra}
                </AttachDef>
              </SAttachableComponentParams>
              #{components_extra}
            </Components>
          </EntityClassDefinition.#{key}>
        XML
      end
    end
  end
end
