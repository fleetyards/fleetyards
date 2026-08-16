# frozen_string_literal: true

require "test_helper"

module ScData
  module Loader
    class EquipmentLoaderTest < ActiveSupport::TestCase
      setup do
        Equipment.delete_all
        @loader = ::ScData::Loader::EquipmentLoader.new
      end

      test "#all loads personal equipment from game files" do
        @loader.all

        assert_operator Equipment.count, :>=, 500

        sc_keys = Equipment.pluck(:sc_key)
        assert_equal sc_keys.uniq.size, sc_keys.size
      end

      # Asserts the families this parser produces are present and that nothing
      # is left unsorted, rather than that these are the only two there will
      # ever be -- the character trees add their own.
      test "#all sorts every item into a family the model knows" do
        @loader.all

        assert_empty Equipment.where(equipment_type: nil).pluck(:sc_key)
        assert_empty Equipment.where.not(equipment_type: Equipment::EQUIPMENT_TYPES).pluck(:equipment_type)

        families = Equipment.distinct.pluck(:equipment_type)

        assert_includes families, "weapon"
        assert_includes families, "weapon_attachment"
      end

      # Magazines are WeaponAttachment in the game's own taxonomy, which is why
      # ammunition is not a family of its own here.
      test "#all files magazines as attachments rather than a family of their own" do
        @loader.all

        magazine = Equipment.find_by(sc_key: "behr_rifle_ballistic_01_mag")

        assert_equal "weapon_attachment", magazine.equipment_type
        assert_equal "magazine", magazine.item_type
      end

      test "#all reads the spec block for the type, class and numbers" do
        @loader.all

        rifle = Equipment.find_by(sc_key: "behr_rifle_ballistic_01")

        assert_equal "P4-AR Rifle", rifle.name
        assert_equal "assault_rifle", rifle.item_type
        assert_equal "ballistic", rifle.weapon_class
        assert_equal 550, rifle.rate_of_fire
        assert_equal 50, rifle.range
        assert_equal 40, rifle.storage
      end

      test "#all leaves the description as prose once the spec block is read" do
        @loader.all

        description = Equipment.find_by(sc_key: "behr_rifle_ballistic_01").description

        assert_no_match(/Item Type:|Rate Of Fire:|Magazine Size:/, description)
        assert_match(/collapsible stock/, description)
      end

      test "#all resolves the manufacturer from the record" do
        ::ScData::Loader::ManufacturersLoader.new.all

        @loader.all

        assert_equal "Behring", Equipment.find_by(sc_key: "behr_rifle_ballistic_01").manufacturer&.name
      end

      # A 64px loadout icon shared by every variant of a weapon, and named by no
      # attachment at all. Stored against the day the export carries textures;
      # nothing resolves the path today.
      test "#all records the loadout icon the game names for a weapon" do
        @loader.all

        assert_equal "ui/textures/ea/loadouticons/behring_p4_ar_rifle_64.tif",
          Equipment.find_by(sc_key: "behr_rifle_ballistic_01").icon
      end

      test "#all leaves the icon empty for the attachments that name none" do
        @loader.all

        assert_empty Equipment.where(equipment_type: "weapon_attachment").where.not(icon: nil)
      end

      test "#all hides skins and dev copies but keeps the item they copy" do
        @loader.all

        assert_not Equipment.find_by(sc_key: "grin_multitool_01").hidden?
        assert_predicate Equipment.find_by(sc_key: "grin_multitool_01_ai"), :hidden?
        assert_predicate Equipment.find_by(sc_key: "lbco_optics_tsco_x16_s3_acid01"), :hidden?
      end

      test "#all leaves few visible items sharing a name for a picker to show" do
        @loader.all

        duplicated = Equipment.visible.group(:slug).having("count(*) > 1").count

        assert_operator duplicated.size, :<=, 25,
          "visible duplicates: #{duplicated.keys.sort.join(", ")}"
      end

      # A new build leaves a dropped record on its old version, so current_version
      # filters it out. Re-importing the build we are already on does not: the
      # row keeps claiming it, and the picker keeps offering it.
      test "#all stops a dropped record claiming the build it is no longer in" do
        @loader.all

        retired = create(:equipment, sc_key: "gone_from_the_export", version: Rails.configuration.sc_data[:version])

        @loader.all

        assert Equipment.exists?(retired.id), "the row has to stay for existing references"
        assert_nil retired.reload.version
        assert_not Equipment.current_version.exists?(retired.id)
      end

      test "#all leaves the records still in the export on the current build" do
        @loader.all
        @loader.all

        assert_operator Equipment.current_version.count, :>=, 4_000
      end

      test "#all is idempotent" do
        @loader.all
        count = Equipment.count

        assert_no_difference -> { Equipment.count } do
          @loader.all
        end

        assert_equal count, Equipment.count
      end
    end
  end
end
