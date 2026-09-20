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

    # Not the digest of nothing. `SHA256("")` is a real-looking answer to "which
    # tree is this?", and it would be recorded and compared as though it meant
    # something -- where nil falls into the "cannot tell" guard readers have.
    test ".checksum says nothing about a tree that is not there" do
      assert_nil ::ScData::ParsedTree.checksum(File.join(@root, "nope"))
    end

    test ".checksum says nothing about a tree holding only its manifest" do
      FileUtils.rm_rf(File.join(@root, "models"))
      FileUtils.rm_rf(File.join(@root, "items"))
      write("version.json", "{}")

      assert_nil ::ScData::ParsedTree.checksum(@root)
    end

    # A parse and a push both have every digest in hand already.
    test ".checksum uses a walk the caller hands it" do
      handed = {"only/this.json" => "deadbeef"}

      assert_equal ::ScData::ParsedTree.checksum(@root, handed),
        Digest::SHA256.hexdigest("only/this.json:deadbeef")
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
