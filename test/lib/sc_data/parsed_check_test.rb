# frozen_string_literal: true

require "test_helper"

module ScData
  class ParsedCheckTest < ActiveSupport::TestCase
    ENVIRONMENT = "test"
    VERSION = "1.0.0-test.1"

    # Every catalogue at one file, so a tree can be built in a handful of writes
    # and a floor can still be asserted against the real ones.
    FLOORS = ::ScData::ParsedCheck::CATALOGUES.transform_values { 1 }.freeze

    setup do
      @root = Dir.mktmpdir
    end

    teardown do
      FileUtils.remove_entry(@root)
    end

    private def check(floors: FLOORS, environment: ENVIRONMENT, expected_version: VERSION)
      ::ScData::ParsedCheck.new(
        environment, base_folder: @root, expected_version:, floors:
      ).call
    end

    private def write(path, content)
      target = File.join(@root, "parsed", ENVIRONMENT, path)
      FileUtils.mkdir_p(File.dirname(target))
      File.write(target, content)
      target
    end

    private def write_record(folder, name, attributes)
      write("#{folder}/#{name}.json", JSON.pretty_generate(attributes))
    end

    # A tree with one record per catalogue, each carrying the field that
    # identifies it there.
    private def write_tree(version: VERSION, environment: ENVIRONMENT)
      write("version.json", JSON.pretty_generate({version:, environment:, parsed_at: Time.current.utc.iso8601}))

      ::ScData::ParsedCheck::CATALOGUES.each do |folder, catalogue|
        write_record(folder, "record", {catalogue.key => "a_record"})
      end
    end

    # --- A tree with nothing wrong with it --------------------------------

    test "#call passes a tree carrying every catalogue and the build it claims" do
      write_tree

      result = check

      assert_predicate result, :ok?
      assert_equal 1, result.stats["items"][:files]
    end

    # --- The tree itself --------------------------------------------------

    test "#call reports a tree that is not there" do
      result = check

      assert_not_predicate result, :ok?
      assert_match(/no parsed tree/, result.problems.first)
    end

    test "#call reports a tree with no version.json" do
      write_tree
      FileUtils.rm(File.join(@root, "parsed", ENVIRONMENT, "version.json"))

      assert_match(/no version.json/, check.problems.first)
    end

    # The pointer in the config and the files in the bucket disagreeing is the
    # one failure a load cannot survive: rows of one build end up stamped with
    # the version of another.
    test "#call reports a tree claiming a build other than the configured one" do
      write_tree(version: "9.9.9-test.2")

      problem = check.problems.first

      assert_includes problem, 'names build "9.9.9-test.2"'
      assert_includes problem, %(configured for "#{VERSION}")
    end

    test "#call reports a tree claiming another environment" do
      write_tree(environment: "live")

      assert_match(/names environment "live"/, check.problems.first)
    end

    # --- Catalogues -------------------------------------------------------

    test "#call reports a catalogue with no files" do
      write_tree
      FileUtils.rm_rf(File.join(@root, "parsed", ENVIRONMENT, "models"))

      assert_includes check.problems, "models: no files at all"
    end

    # The floors carried by the class, against a tree with one file in each:
    # what a half-finished upload or a parse that died between catalogues leaves
    # behind, and the reason a count alone is worth asserting.
    test "#call reports a catalogue short of the files a build produces" do
      write_tree

      problems = check(floors: {}).problems

      ::ScData::ParsedCheck::CATALOGUES.each_key do |folder|
        assert(problems.any? { |problem| problem.start_with?("#{folder}: 1 files, short of") }, "#{folder} was not reported")
      end
    end

    test "#call reports a record with no key of its own" do
      write_tree
      write_record("items", "nameless", {"key" => " "})

      assert_includes check.problems, "items/nameless.json: no key"
    end

    test "#call reports a record that does not parse" do
      write_tree
      write("items/broken.json", "{")

      assert(check.problems.any? { |problem| problem.start_with?("items/broken.json: does not parse") })
    end

    # --- Artwork ----------------------------------------------------------

    test "#call passes a record whose icon is in the tree under the format the export ships" do
      write_tree
      write_record("items", "painted", {"key" => "painted", "icon" => "ui/sharedassets/paintcolorlogos/swatch.tif"})
      write("icons/ui/sharedassets/paintcolorlogos/swatch.png", "art")

      result = check

      assert_predicate result, :ok?
      assert_equal 1, result.stats["items"][:icons_named]
      assert_equal 0, result.stats["items"][:icons_absent]
    end

    # The failure this check was written for: a path with the other separator
    # is copied under a name no glob can match, and the record points at
    # nothing for as long as nobody counts.
    test "#call reports an icon path the tree cannot hold" do
      write_tree
      write_record("items", "painted", {"key" => "painted", "icon" => "ui\\sharedassets\\paintcolorlogos\\swatch.tif"})

      assert(check.problems.any? { |problem| problem.include?("is not a path this tree can hold") })
    end

    # Art the export does not ship is the game's omission rather than a broken
    # parse -- eight manufacturers are in exactly that position.
    test "#call counts a lone icon the export never shipped without failing" do
      write_tree
      25.times { |index| write_record("items", "item_#{index}", {"key" => "item_#{index}", "icon" => "ui/icons/item_#{index}.tif"}) }
      24.times { |index| write("icons/ui/icons/item_#{index}.png", "art") }

      result = check

      assert_predicate result, :ok?
      assert_equal 1, result.stats["items"][:icons_absent]
    end

    test "#call reports artwork missing by more than a stray record" do
      write_tree
      20.times { |index| write_record("items", "item_#{index}", {"key" => "item_#{index}", "icon" => "ui/icons/item_#{index}.tif"}) }

      assert_includes check.problems, "items: 20 of 20 named icons are not in the tree"
    end

    # --- Half-written files -----------------------------------------------

    test "#call reports a file of no bytes" do
      write_tree
      write("icons/ui/icons/cut_short.png", "")

      assert_includes check.problems, "icons/ui/icons/cut_short.png: empty file"
    end

    # --- The tree that is actually loaded ---------------------------------

    # Deliberately the real tree, and the reason this class exists: a build that
    # arrives half-uploaded, a category the export renamed, a parse that stopped
    # between catalogues. None of those raise anywhere -- they produce a tree
    # that loads and quietly retires whatever it no longer carries.
    test "#call passes the parsed tree the configured build points at" do
      result = ::ScData::ParsedCheck.new.call

      assert_predicate result, :ok?, result.problems.first(20).join("\n")
    end
  end
end
