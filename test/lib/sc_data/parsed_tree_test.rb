# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  class ParsedTreeTest < ActiveSupport::TestCase
    setup do
      @root = Dir.mktmpdir
      write("models/aurora.json", '{"name":"Aurora"}')
      write("items/laser.json", '{"name":"Laser"}')
    end

    teardown do
      FileUtils.remove_entry(@root)
    end

    test ".checksum is stable for a tree that has not changed" do
      assert_equal ::ScData::ParsedTree.checksum(@root), ::ScData::ParsedTree.checksum(@root)
    end

    test ".checksum moves when a file's content changes" do
      before = ::ScData::ParsedTree.checksum(@root)

      write("models/aurora.json", '{"name":"Aurora LN"}')

      assert_not_equal before, ::ScData::ParsedTree.checksum(@root)
    end

    test ".checksum moves when a file is added or removed" do
      before = ::ScData::ParsedTree.checksum(@root)

      write("models/avenger.json", '{"name":"Avenger"}')
      added = ::ScData::ParsedTree.checksum(@root)

      assert_not_equal before, added

      FileUtils.rm(File.join(@root, "models/avenger.json"))

      assert_equal before, ::ScData::ParsedTree.checksum(@root)
    end

    # A path carries meaning of its own -- `ModelsLoader` reads a model's
    # in-game-ness off file existence -- so the same bytes under another name
    # are a different tree.
    test ".checksum moves when a file is renamed" do
      before = ::ScData::ParsedTree.checksum(@root)

      FileUtils.mv(File.join(@root, "models/aurora.json"), File.join(@root, "models/aurora-ln.json"))

      assert_not_equal before, ::ScData::ParsedTree.checksum(@root)
    end

    # The manifest carries the checksum, so counting it would be circular, and
    # its `parsed_at` moves on every parse -- which would make two identical
    # trees look different.
    test ".checksum ignores the manifest it is written into" do
      before = ::ScData::ParsedTree.checksum(@root)

      write("version.json", '{"version":"1.0.0","parsed_at":"2026-09-20T00:00:00Z"}')

      assert_equal before, ::ScData::ParsedTree.checksum(@root)
    end

    test ".checksum answers for a tree that is not there" do
      assert_equal ::ScData::ParsedTree.checksum(File.join(@root, "nope")),
        ::ScData::ParsedTree.checksum(File.join(@root, "also-nope"))
    end

    test ".files skips directories and the manifest" do
      write("version.json", "{}")
      FileUtils.mkdir_p(File.join(@root, "icons/empty"))

      assert_equal ["items/laser.json", "models/aurora.json"], ::ScData::ParsedTree.files(@root).keys.sort
    end

    private def write(path, content)
      target = File.join(@root, path)

      FileUtils.mkdir_p(File.dirname(target))
      File.write(target, content)
    end
  end
end
