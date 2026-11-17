# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class GalaxyParserTest < ActiveSupport::TestCase
      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"

        write("Data/Localization/english/global.ini", "")
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      test "#systems upper-cases the game's system name and marks those the export ships" do
        galaxy
        placements(%w[stanton])

        stanton, elsin = parser.systems

        assert_equal "STANTON", stanton[:code]
        assert_equal [49.534718, -2.6339645, 16.475292], stanton[:position]
        assert_equal "single_star", stanton[:system_type]
        assert_equal ["UEE"], stanton[:affiliations]
        assert stanton[:in_game]

        assert_equal "EL'SIN", elsin[:code]
        assert_equal "binary", elsin[:system_type]
        refute elsin[:in_game]
      end

      test "#systems has nothing in game for an export without placements" do
        galaxy

        assert parser.systems.none? { |system| system[:in_game] }
      end

      test "#tunnels names both ends by system code" do
        galaxy

        assert_equal [{key: "STANTON-EL'SIN", entry_code: "STANTON", exit_code: "EL'SIN", size: "medium", bidirectional: true}], parser.tunnels
      end

      test "#all writes a file per system and tunnel" do
        galaxy
        parser.all

        assert File.exist?("#{@base_folder}/parsed/test/star_systems/stanton.json")
        assert File.exist?("#{@base_folder}/parsed/test/jump_tunnels/stanton-el'sin.json")
      end

      test "#all writes nothing for an export without the galaxy file" do
        parser.all

        refute File.exist?("#{@base_folder}/parsed/test/star_systems")
      end

      private def parser
        ::ScData::Parser::GalaxyParser.new(base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test")
      end

      private def galaxy
        write("derived/galaxy.json", {
          source: "https://robertsspaceindustries.com/api/starmap/bootup",
          systems: [
            {system: "stanton", name: "Stanton", pos: [49.534718, -2.6339645, 16.475292], type: "SINGLE_STAR", status: "P", size: 4.85, affiliation: ["UEE"]},
            {system: "el'sin", name: "El'sin", pos: [80.758041, 70.457497, 24.673809], type: "BINARY", status: "N", size: 0.0, affiliation: ["Xi'an"]}
          ],
          tunnels: [
            {size: "M", direction: "B", entry: {system: "stanton", code: "STANTON.JUMPPOINTS.ELSIN"}, exit: {system: "el'sin", code: "ELSIN.JUMPPOINTS.STANTON"}}
          ]
        })
      end

      private def placements(systems)
        write("derived/starmap.json", {systems: systems.map { |system| {system:} }, objects: []})
      end

      private def write(path, content)
        target = "#{@raw_path}/#{path}"

        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, content.is_a?(String) ? content : JSON.generate(content))
      end
    end
  end
end
