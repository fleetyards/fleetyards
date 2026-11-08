# frozen_string_literal: true

require "test_helper"

module Chf
  class ReaderTest < ActiveSupport::TestCase
    FIXTURES = Rails.root.join("test/fixtures/chf")

    private def read(name) = Reader.read(FIXTURES.join("#{name}.chf").binread)

    test "reads what every game file says about its source the way the reference does" do
      FIXTURES.glob("*.chf").each do |path|
        name = path.basename(".chf").to_s
        source = JSON.parse(FIXTURES.join("#{name}.character.json").read)["source"]
        chf = Reader.read(path.binread)

        read = {
          "format_version" => chf["format_version"],
          "dna_stamp" => chf.dig("dna", "stamp"),
          "gender_hash" => chf.dig("dna", "gender_hash"),
          "part_count" => chf.dig("dna", "part_count") || 0
        }

        assert_equal source.slice(*read.keys), read, name
      end
    end

    test "names the equipped ports and the customised materials" do
      chf = read("Macken")

      assert chf["body_tag"].start_with?("25f439d5")
      assert_includes chf["ports"].keys, "hair_itemport"
      assert_includes chf["ports"].keys, "universal_scalp_itemport"
      assert_empty chf["ports"].keys.grep(/\A0x/)
      assert_match(/\A#\h{6}\z/, chf.dig("materials", "Head Material", "subs", 0, "colors", "BodyColor"))
      assert_kind_of Float, chf.dig("materials", "HairDyeMaterial", "subs", 0, "floats", "BaseMelanin")
    end

    test "reads blends blend-major, four per part" do
      parts = read("Macken").dig("dna", "parts")

      assert_equal 12, parts.size
      assert(parts.all? { |blends| blends.size == 4 })
      assert_equal [27, 65535], parts.first.max_by(&:last)
    end

    test "reads a material-only preset as a file without a face or ports" do
      chf = read("regen_boss_hair_color")

      assert_nil chf["dna"]
      assert_empty chf["ports"]
      assert_includes chf["materials"].keys, "HairDyeMaterial"
    end

    test "refuses what is not a character file" do
      assert_raises(Reader::Invalid) { Reader.read("PK\x03\x04 not a chf") }
      assert_raises(Reader::Invalid) { Reader.read("") }
    end

    test "refuses a file whose compressed payload is cut off or corrupt" do
      bytes = FIXTURES.join("Macken.chf").binread

      assert_raises(Reader::Invalid) { Reader.read(bytes.byteslice(0, 40)) }
      assert_raises(Reader::Invalid) { Reader.read(bytes.byteslice(0, 16) + ("\xFF".b * 200)) }
    end

    test "stops decompressing a frame that expands past the size its header claims" do
      frame = Zstd.compress("\0" * 5.megabytes)
      bytes = ["BB", 0, 0, frame.bytesize, 3000].pack("a2vVVV") + frame

      error = assert_raises(Reader::Invalid) { Reader.read(bytes) }
      assert_match(/larger than its header says/, error.message)
    end

    test "refuses a header asking for an oversized payload" do
      bytes = FIXTURES.join("Macken.chf").binread.dup
      bytes[12, 4] = [Reader::MAX_PAYLOAD + 1].pack("V")

      assert_raises(Reader::Invalid) { Reader.read(bytes) }
    end
  end
end
