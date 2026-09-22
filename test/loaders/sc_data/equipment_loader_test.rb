# frozen_string_literal: true

require "test_helper"
require "support/sc_data_fixture_tree"

module ScData
  module Loader
    class EquipmentLoaderTest < ActiveSupport::TestCase
      include ScDataFixtureTree

      setup do
        Equipment.delete_all
      end

      # The parsed files are the parser's output and the loader's input, so the
      # data-shape assertions read them directly. Loading all 4,700-odd rows
      # into the database once per test would cost minutes for no more cover.
      def parsed
        @parsed ||= curated.load_items("equipment").index_by { |item| item[:key] }
      end

      # What a load does to a record is the same whether the export carries two
      # of them or 4,800, and the write is the expensive half: the real tree is
      # three quarters of a minute per call. So the tests that go through the
      # table use the curated export in test/fixtures/sc_data, and only "#all
      # loads the parsed equipment into the table" still writes the real one.
      def curated
        @curated ||= fixture_loader(::ScData::Loader::EquipmentLoader)
      end

      # Magazines are WeaponAttachment in the game's own taxonomy, which is why
      # ammunition is not a family of its own here.
      test "magazines are filed as attachments rather than a family of their own" do
        magazine = parsed["behr_rifle_ballistic_01_mag"]

        assert_equal "weapon_attachment", magazine[:equipment_type]
        assert_equal "magazine", magazine[:item_type]
      end

      test "a medical pen keeps its spec block's type and its prose" do
        medpen = parsed["crlf_consumable_healing_01"]

        assert_equal "MedPen (Hemozal)", medpen[:name]
        assert_equal "medical", medpen[:equipment_type]
        assert_equal "medical_consumable", medpen[:item_type]
        assert_no_match(/Manufacturer:|Item Type:/, medpen[:description])
      end

      # The OxyPen's description names its maker and stops, so the SubType is
      # all there is to file it by.
      test "a consumable with no item type in its block still takes one" do
        assert_equal "medical_consumable", parsed["crlf_consumable_oxygen_01"][:item_type]
      end

      test "a keycard is read from a description that is prose alone" do
        keycard = parsed["fps_consumable_keycard_olp_access"]

        assert_equal "OLP Storage Keycard", keycard[:name]
        assert_equal "keycard", keycard[:item_type]
        assert_match(/grants Orbital Laser Platform employees access/, keycard[:description])
      end

      # fps_consumable_template borrows the MedPen's name outright, so without
      # the template suffix rule the catalogue would show two of them.
      test "the consumable templates are hidden rather than shown twice" do
        assert_predicate parsed["fps_consumable_template"][:hidden], :present?
        assert_equal parsed["crlf_consumable_healing_01"][:name], parsed["fps_consumable_template"][:name]
      end

      test "worn gear takes its slot from the AttachDef type, carried gear has none" do
        assert_equal "helmet", parsed["gys_helmet_03_01_01"][:slot]
        assert_nil parsed["behr_rifle_ballistic_01"][:slot]
      end

      test "a weapon's spec block gives its type, class and numbers" do
        rifle = parsed["behr_rifle_ballistic_01"]

        assert_equal "P4-AR Rifle", rifle[:name]
        assert_equal "assault_rifle", rifle[:item_type]
        assert_equal "ballistic", rifle[:weapon_class]
        assert_equal 550, rifle[:rate_of_fire].to_d
        assert_equal 50, rifle[:range].to_d
        assert_equal 40, rifle[:storage].to_d
      end

      test "an armour spec block gives its protection figures" do
        suit = parsed["clda_env_armor_heavy_suit_01_01_01"]

        assert_equal "Novikov Exploration Suit", suit[:name]
        assert_equal 25, suit[:damage_reduction].to_d
        assert_equal "-225 / 75 °C", suit[:temperature_rating]
        assert_equal 33_600, suit[:radiation_protection].to_d
        assert_equal 147.42, suit[:radiation_scrub_rate].to_d
        assert_equal "all", suit[:backpack_compatibility]
      end

      test "the spec block is stripped, leaving the description as prose" do
        description = parsed["behr_rifle_ballistic_01"][:description]

        assert_no_match(/Item Type:|Rate Of Fire:|Magazine Size:/, description)
        assert_match(/collapsible stock/, description)
      end

      # A 64px loadout icon shared by every variant of a weapon, and named by no
      # attachment at all. Stored against the day the export carries textures.
      test "a weapon records the loadout icon the game names for it" do
        assert_equal "ui/textures/ea/loadouticons/behring_p4_ar_rifle_64.tif",
          parsed["behr_rifle_ballistic_01"][:icon]

        attachments = parsed.values.select { |item| item[:equipment_type] == "weapon_attachment" }

        assert_empty attachments.select { |item| item[:icon].present? }
      end

      test "skins and dev copies are hidden but the item they copy is not" do
        assert_not parsed["grin_multitool_01"][:hidden]
        assert parsed["grin_multitool_01_ai"][:hidden]
        assert parsed["lbco_optics_tsco_x16_s3_acid01"][:hidden]
        assert parsed["mym_shirt_01_01_02"][:hidden]

        # The name test is what keeps real items in: a rifle's magazine key
        # shares the rifle's prefix, but it is named for the magazine.
        assert_not parsed["behr_rifle_ballistic_01_mag"][:hidden]
      end

      # Clothing ships a record per colourway, all under one name, so without
      # the skin rule a picker would list the Davlos Shirt seventeen times.
      test "few visible items share a name for a picker to show" do
        visible = parsed.values.reject { |item| item[:hidden] }
        duplicated = visible.group_by { |item| item[:name] }.select { |_, group| group.size > 1 }

        assert_operator duplicated.size, :<=, 25,
          "visible duplicates: #{duplicated.keys.sort.join(", ")}"
      end

      test "#all resolves the manufacturer from the record" do
        fixture_loader(::ScData::Loader::ManufacturersLoader).all

        curated.all

        assert_equal "Behring", Equipment.find_by(sc_key: "behr_rifle_ballistic_01").manufacturer&.name
      end

      # A new build leaves a dropped record on its old version, so current_version
      # filters it out. Re-importing the build we are already on does not: the
      # row keeps claiming it, and the picker keeps offering it.
      test "#all stops a dropped record claiming the build it is no longer in" do
        curated.all

        retired = create(:equipment, sc_key: "gone_from_the_export", version: ScData::Source.version)

        curated.all

        assert Equipment.exists?(retired.id), "the row has to stay for existing references"
        assert_nil retired.reload.version
        assert_not Equipment.current_version(true, fixture_source).exists?(retired.id)
      end

      test "#all leaves the records still in the export on the current build" do
        curated.all
        curated.all

        assert_predicate Equipment.count, :positive?
        assert_equal Equipment.pluck(:sc_key).sort,
          Equipment.current_version(true, fixture_source).pluck(:sc_key).sort
      end

      # A tree that carries no equipment at all is what a build whose files
      # failed to sync looks like. Retiring on that would empty the catalogue
      # the first time one did.
      test "#all retires nothing when the export parsed no records" do
        curated.all
        current = Equipment.current_version.count

        empty_tree_loader(::ScData::Loader::EquipmentLoader).all

        assert_equal current, Equipment.current_version.count
      end

      test "every parsed item states what it costs an inventory" do
        without = parsed.values.reject { |item| item[:volume].to_f.positive? }

        assert_operator without.size, :<=, 10, "unmeasured: #{without.map { |item| item[:key] }.first(10)}"
      end

      test "a measured piece carries both the volume and the box it fills" do
        helmet = parsed["gys_helmet_03_01_01"]

        assert_operator helmet[:volume], :>, 0
        assert_operator helmet[:volume], :<, 1, "gear is measured in fractions of an SCU"
        assert_equal %w[x y z], helmet[:volume_dimensions].keys.sort
        assert(helmet[:volume_dimensions].values.all? { |side| side.to_f.positive? })
      end

      # One microSCU in a 0.15m box is what CIG leaves on a record nobody has
      # measured, so it has to read as unknown rather than as almost nothing.
      test "the unmeasured placeholder is left blank rather than stored" do
        placeholder = parsed.values.find { |item| item[:volume].blank? }

        assert placeholder, "expected at least one unmeasured record"
        assert_nil placeholder[:volume]
      end

      # That the export measures its gear is asserted above, on the real tree.
      # What is left for a load is carrying both halves of the measurement onto
      # the row.
      test "#all persists the volume onto the record" do
        curated.all

        measured = Equipment.current_version(true, fixture_source).where.not(volume: nil)

        # Every record but the unmeasured placeholder, which has to reach the row
        # as unknown rather than as the almost-nothing the export states.
        assert_equal Equipment.count - 1, measured.count
        assert_equal measured.count,
          Equipment.current_version(true, fixture_source).where.not(volume_dimensions: nil).count

        assert_nil Equipment.find_by(sc_key: "behr_ltp_kinetic_01").volume

        helmet = Equipment.find_by(sc_key: "gys_helmet_03_01_01")

        assert_operator helmet.volume, :>, 0
        assert_equal %w[x y z], helmet.volume_dimensions.keys.sort
      end

      test "#all is idempotent" do
        curated.all
        count = Equipment.count

        assert_no_difference -> { Equipment.count } do
          curated.all
        end

        assert_equal count, Equipment.count
      end
    end
  end
end
