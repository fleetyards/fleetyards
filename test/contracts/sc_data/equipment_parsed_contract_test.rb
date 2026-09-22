# frozen_string_literal: true

require "test_helper"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # The equipment questions asked of the export as a whole: which families it
    # files its gear under, and whether a taxonomy the parser leans on still
    # holds across all ~4,800 records rather than across the fourteen the fixture
    # tree carries. See test/support/sc_data_contract_tree.rb.
    class EquipmentParsedContractTest < ActiveSupport::TestCase
      include ScDataContractTree

      setup do
        require_real_tree
      end

      # The parsed files are the parser's output and the loader's input, read
      # without writing a row.
      def parsed
        @parsed ||= real_tree_loader(::ScData::Loader::EquipmentLoader)
          .load_items("equipment").index_by { |item| item[:key] }
      end

      test "every parsed item carries a family the model knows" do
        assert_empty parsed.values.reject { |item| item[:equipment_type].present? }.map { |item| item[:key] }

        assert_equal %w[armor clothing hacking_tool medical undersuit weapon weapon_attachment],
          parsed.values.filter_map { |item| item[:equipment_type] }.uniq.sort
      end

      # Neither Type nor SubType separates a keycard from a hacking chip --
      # SystemAccess holds both and the orbital keycards are filed under
      # Hacking -- so both land in the family the game gives them.
      test "consumables split into the medical and access families" do
        consumables = parsed.values.select { |item| item[:key].include?("_consumable_") }

        assert_equal %w[hacking_tool medical],
          consumables.filter_map { |item| item[:equipment_type] }.uniq.sort
        assert_equal %w[data_drive keycard medical_consumable],
          consumables.filter_map { |item| item[:item_type] }.uniq.sort
      end

      # The drives share SystemAccess with the keycards -- the three ASD ones from
      # the Onyx facility and the generic mission drive alike -- so only the key
      # keeps them out of a filter for the cards that open a door.
      test "the data drives are not filed with the keycards" do
        drives = parsed.values.select { |item| item[:key].include?("_harddrive_") }

        assert_equal ["ASD Data Drive", "ASD Memory Drive", "ASD Secure Drive", "Data Drive"],
          drives.map { |item| item[:name] }.sort
        assert_equal ["data_drive"], drives.map { |item| item[:item_type] }.uniq
        assert_equal ["hacking_tool"], drives.map { |item| item[:equipment_type] }.uniq
      end

      test "the two clothing torso layers land in different slots" do
        clothing = parsed.values.select { |item| item[:equipment_type] == "clothing" }
        slots = clothing.filter_map { |item| item[:slot] }.uniq

        assert_includes slots, "shirt"
        assert_includes slots, "jacket"
      end

      # Capacity is written "8.0 µSCU" on a suit but "180K µSCU" on a backpack,
      # while "50 m" of range is metres rather than fifty million.
      test "a thousands suffix scales a capacity without catching a unit" do
        armor = parsed.values.select { |item| item[:equipment_type] == "armor" }

        assert_operator armor.filter_map { |item| item[:storage]&.to_d }.max, :>=, 100_000
        assert_equal 50, parsed["behr_rifle_ballistic_01"][:range].to_d
      end
    end
  end
end
