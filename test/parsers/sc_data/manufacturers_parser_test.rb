# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class ManufacturersParserTest < ActiveSupport::TestCase
      setup do
        @base_folder = Dir.mktmpdir

        FileUtils.mkdir_p("#{@base_folder}/raw/1.0.0/Data/Localization/english")
        File.write("#{@base_folder}/raw/1.0.0/Data/Localization/english/global.ini", "")

        @parser = ::ScData::Parser::ManufacturersParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      # mxox.xml carries a copy-pasted Localization block asking for Aegis'
      # name, which is how the table grew four rows called "Aegis Dynamics".
      test "#parse_manufacturer prefers the record's own name over the one its block asks for" do
        @parser.translations = {
          "manufacturer_NameAEGS" => "Aegis Dynamics",
          "manufacturer_NameMXOX" => "maxOx"
        }

        result = @parser.parse_manufacturer(record("MXOX", name_key: "@manufacturer_NameAEGS"))

        assert_equal "maxOx", result[:name]
      end

      # GAM asks for GAMA and defines no own key: the two spell one company
      # differently rather than pointing at another, so it must keep resolving.
      test "#parse_manufacturer follows the block when the record defines no name of its own" do
        @parser.translations = {"manufacturer_NameGAMA" => "Gatac Manufacture"}

        result = @parser.parse_manufacturer(record("GAM", name_key: "@manufacturer_NameGAMA"))

        assert_equal "Gatac Manufacture", result[:name]
      end

      test "#parse_manufacturer takes the name from the overrides when the export defines none" do
        override("FSKI" => {"name" => "Firestorm Kinetics"})
        @parser.translations = {"manufacturer_NameAEGS" => "Aegis Dynamics"}

        result = @parser.parse_manufacturer(record("FSKI", name_key: "@manufacturer_NameAEGS"))

        assert_equal "Firestorm Kinetics", result[:name]
      end

      test "#parse_manufacturer skips a record the overrides mark as skip" do
        override("TRAS" => {"skip" => true})
        @parser.translations = {"manufacturer_NameAEGS" => "Aegis Dynamics"}

        assert_nil @parser.parse_manufacturer(record("TRAS", name_key: "@manufacturer_NameAEGS"))
      end

      # A block that named the wrong manufacturer names their history too, and
      # Aegis' story under "Firestorm Kinetics" is worse than no story.
      test "#parse_manufacturer drops the description when the name came from an override" do
        override("FSKI" => {"name" => "Firestorm Kinetics"})
        @parser.translations = {
          "manufacturer_NameAEGS" => "Aegis Dynamics",
          "manufacturer_DescAEGS" => "Aegis grew to prominence..."
        }

        result = @parser.parse_manufacturer(
          record("FSKI", name_key: "@manufacturer_NameAEGS", desc_key: "@manufacturer_DescAEGS")
        )

        assert_nil result[:description]
      end

      test "#parse_manufacturer drops the description when the block pointed at another record" do
        @parser.translations = {
          "manufacturer_NameAEGS" => "Aegis Dynamics",
          "manufacturer_DescAEGS" => "Aegis grew to prominence...",
          "manufacturer_NameMXOX" => "maxOx"
        }

        result = @parser.parse_manufacturer(
          record("MXOX", name_key: "@manufacturer_NameAEGS", desc_key: "@manufacturer_DescAEGS")
        )

        assert_equal "maxOx", result[:name]
        assert_nil result[:description]
      end

      test "#parse_manufacturer keeps the description of a record whose block is its own" do
        @parser.translations = {
          "manufacturer_NameTALN" => "Talon",
          "manufacturer_DescTALN" => "Talon builds things."
        }

        result = @parser.parse_manufacturer(
          record("TALN", name_key: "@manufacturer_NameTALN", desc_key: "@manufacturer_DescTALN")
        )

        assert_equal "Talon", result[:name]
        assert_equal "Talon builds things.", result[:description]
      end

      test "#parse_manufacturer prefers the record's own description over the block's" do
        @parser.translations = {
          "manufacturer_NameGAMA" => "Gatac Manufacture",
          "manufacturer_DescGAMA" => "Wrong company.",
          "manufacturer_DescGAM" => "Gatac builds things."
        }

        result = @parser.parse_manufacturer(
          record("GAM", name_key: "@manufacturer_NameGAMA", desc_key: "@manufacturer_DescGAMA")
        )

        assert_equal "Gatac builds things.", result[:description]
      end

      test "#parse_manufacturer ignores a record without a code" do
        assert_nil @parser.parse_manufacturer(record(nil))
      end

      # Guards the shipped file rather than the mechanism: these four entries are
      # what keeps the export's copy-pasted records out of the table.
      test "the shipped overrides name the records the export gets wrong" do
        overrides = ::ScData::Parser::ManufacturersParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        ).overrides

        assert_equal "Firestorm Kinetics", overrides.dig("FSKI", "name")
        assert_equal "Preacher Armaments", overrides.dig("PRAR", "name")
        assert overrides.dig("TRAS", "skip")
        assert overrides.dig("GHEX", "skip")
      end

      # Seeds the memo `#overrides` fills from config, so a test names its own
      # corrections without touching the shipped file.
      private def override(entries)
        @parser.instance_variable_set(:@overrides, entries)
      end

      private def record(code, name_key: "@LOC_EMPTY", desc_key: "@LOC_EMPTY")
        {
          "Code" => code,
          "__ref" => "00000000-0000-0000-0000-00000000beef",
          "Logo" => "UI/SharedAssets/ManufacturerLogos/Example_256.tif",
          "Localization" => {
            "Name" => name_key,
            "ShortName" => "@LOC_EMPTY",
            "Description" => desc_key
          }
        }
      end
    end
  end
end
