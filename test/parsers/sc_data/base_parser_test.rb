# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class BaseParserTest < ActiveSupport::TestCase
      VECTOR = "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'><rect width='16' height='16'/></svg>"

      setup do
        @base_folder = Dir.mktmpdir
        @export_path = "#{@base_folder}/parsed/test"

        # The only file the constructor insists on.
        FileUtils.mkdir_p("#{@base_folder}/raw/1.0.0/Data/Localization/english")
        File.write("#{@base_folder}/raw/1.0.0/Data/Localization/english/global.ini", "")

        @parser = ::ScData::Parser::BaseParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      # Without this the file survives every later parse, the loader keeps
      # reading it as part of the build, and nothing downstream can tell it
      # apart from a record the game files still carry.
      test "#save_items drops the file of a record the run no longer parses" do
        write_parsed("items", "gone")

        @parser.send(:save_items, [{key: "kept"}], folder: "items")

        assert_equal ["kept.json"], parsed_files("items")
      end

      # `items` and `models` are filled by several passes, so clearing per call
      # would leave only whatever the last pass wrote.
      test "#save_items keeps what an earlier pass of the same run wrote" do
        @parser.send(:save_items, [{key: "first"}], folder: "items")
        @parser.send(:save_items, [{key: "second"}], folder: "items")

        assert_equal ["first.json", "second.json"], parsed_files("items")
      end

      test "#save_items leaves the folder alone when a pass parsed nothing" do
        write_parsed("items", "kept")

        @parser.send(:save_items, [], folder: "items")

        assert_equal ["kept.json"], parsed_files("items")
      end

      test "#save_items clears each folder on its own first write" do
        write_parsed("items", "gone")
        write_parsed("models", "also_gone")

        @parser.send(:save_items, [{key: "kept"}], folder: "items")
        @parser.send(:save_items, [{key: "kept_model"}], folder: "models")

        assert_equal ["kept.json"], parsed_files("items")
        assert_equal ["kept_model.json"], parsed_files("models")
      end

      # The record names the source art -- a .tif -- and the export ships the
      # picture beside it under the same name.
      test "#save_icon copies the png the export ships for a record's tif" do
        FileUtils.mkdir_p("#{@base_folder}/raw/1.0.0/Data/ui/logos")
        source = "#{@base_folder}/raw/1.0.0/Data/ui/logos/acme_256.png"
        FileUtils.cp(Rails.root.join("test/fixtures/files/test.png"), source)

        target = @parser.send(:save_icon, "ui/logos/acme_256.tif")

        assert_equal "#{@export_path}/icons/ui/logos/acme_256.png", target
        assert_equal File.binread(source), File.binread(target)
      end

      # A vector is carried over as it is: it draws at whatever size a panel
      # asks for, and rasterizing here would fix it at one.
      test "#save_icon copies a vector icon unchanged" do
        source = write_asset("ui/logos/acme.svg", VECTOR)

        target = @parser.send(:save_icon, "ui/logos/acme.svg")

        assert_equal "#{@export_path}/icons/ui/logos/acme.svg", target
        assert_equal File.binread(source), File.binread(target)
      end

      # Every catalogue writes into the same icons root, so sweeping that root
      # would leave whichever parser ran last as the only one with artwork.
      test "#save_icon leaves the icons another catalogue wrote alone" do
        write_asset("ui/logos/acme.svg", VECTOR)
        write_asset("ui/items/widget.svg", VECTOR)

        @parser.send(:save_icon, "ui/logos/acme.svg")

        # A second catalogue is a second parser, with its own idea of what it
        # has already cleared.
        ::ScData::Parser::BaseParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        ).send(:save_icon, "ui/items/widget.svg")

        assert_path_exists "#{@export_path}/icons/ui/logos/acme.svg"
        assert_path_exists "#{@export_path}/icons/ui/items/widget.svg"
      end

      test "#save_icon drops an icon its own folder no longer names" do
        FileUtils.mkdir_p("#{@export_path}/icons/ui/logos")
        File.write("#{@export_path}/icons/ui/logos/gone.png", "")
        write_asset("ui/logos/acme.svg", VECTOR)

        @parser.send(:save_icon, "ui/logos/acme.svg")

        assert_equal ["acme.svg"], Dir.children("#{@export_path}/icons/ui/logos")
      end

      test "#save_icon writes nothing when the export carries no such asset" do
        assert_nil @parser.send(:save_icon, "ui/logos/missing_256.tif")
        assert_not File.directory?("#{@export_path}/icons")
      end

      # The export ships a raster of every vector beside it under the same name,
      # so which of the two a record resolves to used to come down to the case of
      # the filename: Inv_Icon_Gold.svg sorts before inv_icon_gold.png and lost
      # to it, while icon_brand_aegis.svg won.
      test "#save_icon prefers the vector over the raster the export ships beside it" do
        write_asset("ui/logos/Acme.svg", VECTOR)
        FileUtils.cp(Rails.root.join("test/fixtures/files/test.png"), "#{@base_folder}/raw/1.0.0/Data/ui/logos/acme.png")

        assert_equal "#{@export_path}/icons/ui/logos/acme.svg", @parser.send(:save_icon, "ui/logos/acme.tif")
      end

      # The export still carries the textures its pictures were made from.
      # Copying one would leave a record pointing at a file nothing can draw,
      # so a texture on its own counts as no asset at all.
      test "#save_icon passes over a texture with no drawable copy" do
        write_asset("ui/logos/acme_256.dds", "DDS ")

        assert_nil @parser.send(:save_icon, "ui/logos/acme_256.tif")
      end

      # A port and the item that fits it name the same tag in different
      # spellings -- one side marks it with a `$`, the other does not -- and the
      # whole point of the tag is that the two sides compare equal.
      test "#normalize_tags drops the marker the files put on a matched tag" do
        assert_equal ["Eclipse_BombRack"], @parser.send(:normalize_tags, "$Eclipse_BombRack")
        assert_equal ["Eclipse_BombRack"], @parser.send(:normalize_tags, "Eclipse_BombRack")
      end

      test "#normalize_tags splits a list and keeps each tag once" do
        assert_equal(
          ["flightReady", "Retaliator_BombRack_Front"],
          @parser.send(:normalize_tags, "flightReady $Retaliator_BombRack_Front flightReady")
        )
      end

      test "#normalize_tags answers an empty list for a port that names none" do
        assert_equal [], @parser.send(:normalize_tags, nil)
        assert_equal [], @parser.send(:normalize_tags, "")
      end

      # The two ways the export declares a key that a record then asks for in a
      # third: `translate` matches exactly and answers neither.
      test "#localize_name resolves a key the export declares with a plural marker" do
        @parser.translations = {"item_Name_qrt_combat_medium_arms_01_02_01,P" => "Testudo Arms Purgatory Camo"}

        assert_nil @parser.send(:translate, "@item_Name_qrt_combat_medium_arms_01_02_01")
        assert_equal(
          "Testudo Arms Purgatory Camo",
          @parser.send(:localize_name, "@item_Name_qrt_combat_medium_arms_01_02_01")
        )
      end

      test "#localize_name resolves a key the export declares in another case" do
        @parser.translations = {"item_namearmr_aegs_redeemer" => "Aegis Redeemer Ship Armor"}

        assert_nil @parser.send(:translate, "@item_NameARMR_AEGS_Redeemer")
        assert_equal(
          "Aegis Redeemer Ship Armor",
          @parser.send(:localize_name, "@item_NameARMR_AEGS_Redeemer")
        )
      end

      # The fallback that makes this a safe swap for `translate`: a value the
      # index cannot answer still resolves to whatever `translate` made of it,
      # so no record can come out of this with less of a name than before.
      test "#localize_name passes through a value that is not a key" do
        @parser.translations = {}

        assert_equal "Mission Prospector", @parser.send(:localize_name, "Mission Prospector")
      end

      # These resolve for the first time with the index, and reading them as
      # names would put 25 records called "PH - hdh_boots_01_01_13" in front of
      # a player. No name is the better answer, and the one they have today.
      test "#localize_name drops a name the export has left as a placeholder" do
        @parser.translations = {
          "item_Name_a,P" => "PH - hdh_boots_01_01_13",
          "item_Name_b,P" => "PLACEHOLDER - SPV Jacket",
          "item_Name_c,P" => "PH"
        }

        assert_nil @parser.send(:localize_name, "@item_Name_a")
        assert_nil @parser.send(:localize_name, "@item_Name_b")
        assert_nil @parser.send(:localize_name, "@item_Name_c")
      end

      # Only a leading marker word, so a name that merely starts with those
      # letters is left alone.
      test "#localize_name keeps a name that only begins like a placeholder" do
        @parser.translations = {"item_Name_phase,P" => "PH-13 Phase Rifle"}

        assert_equal "PH-13 Phase Rifle", @parser.send(:localize_name, "@item_Name_phase")
      end

      # `describe` reads the prose `translate` returns, and a description read
      # through the index arrives with its newlines already unescaped -- a
      # different string from the one every parsed tree so far records.
      test "#localize leaves the escaped newlines of `translate` alone" do
        @parser.translations = {"item_Desc_a" => 'Item Type: Turret\n\nA bespoke turret.'}

        assert_equal 'Item Type: Turret\n\nA bespoke turret.', @parser.send(:translate, "@item_Desc_a")
        assert_equal "Item Type: Turret\n\nA bespoke turret.", @parser.send(:localize, "@item_Desc_a")
      end

      # Written once, after every parser has run -- the checksum cannot be
      # known until the last file is on disk. It used to be written by each
      # parser's constructor instead, seven times, before any of them had
      # parsed anything.
      test ".write_manifest stamps the tree with the build and its checksum" do
        write_parsed("items", "kept")

        ::ScData::Parser::BaseParser.write_manifest(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )

        manifest = JSON.parse(File.read("#{@export_path}/version.json"))

        assert_equal "1.0.0", manifest["version"]
        assert_equal "test", manifest["environment"]
        assert_equal ::ScData::ParsedTree.checksum(@export_path), manifest["checksum"]
        assert manifest["parsed_at"].present?
      end

      # Otherwise every parse would look like a change to whoever is deciding
      # whether to reload, because `parsed_at` moves each time.
      test ".write_manifest states the same checksum for an unchanged tree" do
        write_parsed("items", "kept")

        checksums = 2.times.map do
          ::ScData::Parser::BaseParser.write_manifest(
            base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
          )

          JSON.parse(File.read("#{@export_path}/version.json"))["checksum"]
        end

        assert_equal checksums.first, checksums.last
      end

      test ".write_manifest moves the checksum when the tree changes" do
        write_parsed("items", "kept")
        ::ScData::Parser::BaseParser.write_manifest(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
        before = JSON.parse(File.read("#{@export_path}/version.json"))["checksum"]

        write_parsed("items", "another")
        ::ScData::Parser::BaseParser.write_manifest(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )

        assert_not_equal before, JSON.parse(File.read("#{@export_path}/version.json"))["checksum"]
      end

      private def write_asset(path, contents)
        target = "#{@base_folder}/raw/1.0.0/Data/#{path}"

        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, contents)

        target
      end

      private def write_parsed(folder, name)
        FileUtils.mkdir_p("#{@export_path}/#{folder}")
        File.write("#{@export_path}/#{folder}/#{name}.json", "{}")
      end

      private def parsed_files(folder)
        Dir.children("#{@export_path}/#{folder}").sort
      end
    end
  end
end
