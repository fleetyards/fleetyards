# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class BaseParserTest < ActiveSupport::TestCase
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
