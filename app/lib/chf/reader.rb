# frozen_string_literal: true

require "zlib"
require "zstd-ruby"

module Chf
  # Reads a Star Citizen character file, the character creator's export: a
  # small header and a zstd frame holding the face block, the equipped item
  # per port and the customised materials. Names in the file are hashes, so
  # only the ones the catalogue speaks of come out named.
  class Reader
    class Invalid < StandardError; end

    # The largest decompressed payload a game file has is about 3 KB; this
    # only keeps a crafted header from asking for gigabytes.
    MAX_PAYLOAD = 1.megabyte

    PORTS = %w[
      body_itemport head_itemport eyes_itemport hair_itemport eyebrow_itemport eyelashes_itemport
      beard_itemport stubble_itemport universal_scalp_itemport piercings_l_ear_itemport
      piercings_r_ear_itemport piercings_eyebrows_itemport piercings_mouth_itemport
      piercings_nose_itemport teeth_itemport
    ].freeze

    # The port each customisable material belongs to; the file names the
    # material by the zlib CRC32 of "<port>_skinitemport".
    MATERIALS = {
      "head_itemport" => "Head Material", "body_itemport" => "BodyMaterial", "eyes_itemport" => "EyeMaterial",
      "hair_itemport" => "HairDyeMaterial", "beard_itemport" => "BeardDyeMaterial",
      "eyebrow_itemport" => "EyebrowDyeMaterial", "stubble_itemport" => "DyeMaterial",
      "universal_scalp_itemport" => "ScalpMaterial"
    }.freeze

    INT_SUFFIXES = %w[NumTilesU NumTilesV OffsetU OffsetV].freeze

    PARAMS = (
      %w[
        FrecklesAmount FrecklesOpacity SunSpotsAmount SunSpotsOpacity TattooAge TattooHueRotation DyeAmount
        DyeFadeout BaseMelanin BaseMelaninRedness DyePigmentVariation BaseMelaninVariation DyeShift
      ] +
      [1, 2, 3].product(%w[Metalness Smoothness Opacity], %w[R G B]).map { |slot, kind, channel| "Makeup#{slot}#{kind}#{channel}" } +
      [1, 2, 3].map { |slot| "Makeup#{slot}Opacity" } +
      %w[Makeup1 Makeup2 Makeup3 Tattoo].product(INT_SUFFIXES).map(&:join)
    ).freeze

    # Colours are stored under hashes that are not the CRC of these display
    # names, in a stable order.
    COLORS = {
      0xbd530797 => "BodyColor", 0xb29b1d90 => "EyeMakeupColor1", 0xe3230e2f => "EyeMakeupColor2",
      0x2ec0e736 => "EyeMakeupColor3", 0x1a081a93 => "CheekMakeupColor1", 0x4bb0092c => "CheekMakeupColor2",
      0x8653e035 => "CheekMakeupColor3", 0x7d86e792 => "LipMakeupColor1", 0x2c3ef42d => "LipMakeupColor2",
      0xe1dd1d34 => "LipMakeupColor3", 0x442a34ac => "EyeColor", 0x15e90814 => "HairDyeColor1",
      0xa2c7c909 => "HairDyeColor2"
    }.freeze

    CRC32C_TABLE = Array.new(256) do |i|
      8.times.reduce(i) { |c, _| c.odd? ? (c >> 1) ^ 0x82F63B78 : c >> 1 }
    end.freeze

    def self.crc32c(string)
      string.each_byte.reduce(0xFFFFFFFF) { |c, byte| CRC32C_TABLE[(c ^ byte) & 0xFF] ^ (c >> 8) } ^ 0xFFFFFFFF
    end

    NAMES = (PORTS + PARAMS).to_h { |name| [crc32c(name), name] }
      .merge(MATERIALS.to_h { |port, name| [Zlib.crc32("#{port}_skinitemport"), name] })
      .merge(COLORS)
      .freeze

    def self.read(bytes) = new(bytes).read

    def initialize(bytes)
      @file = bytes.b
    end

    # {"container_version", "format_version", "body_tag", "dna" (nil for a
    # material-only preset), "ports" => {port => item guid},
    # "materials" => {name => {"guid", "subs" => [...]}}}
    def read
      raise Invalid, "not a character file" unless @file.start_with?("BB") && @file.bytesize >= 16

      compressed, size = @file.unpack("@8VV")
      raise Invalid, "payload too large" if size > MAX_PAYLOAD

      @bytes = decompress(@file.byteslice(16, compressed), size)
      @offset = 0

      out = {"container_version" => u32, "format_version" => u32, "body_tag" => guid}
      raw(16)
      out["dna"] = dna(raw(u64))
      out["ports"] = {}
      count = u32
      # Without ports this is the material count, otherwise a zero ahead of
      # the port tree.
      u32
      node(out["ports"]) if count.positive?
      raise Invalid, "unexpected material header" unless u32 == 5

      out["materials"] = materials
      out
    rescue RangeError, ArgumentError => e
      raise Invalid, "unreadable character file: #{e.message}"
    end

    # Fed in small slices so a frame that expands far past what its header
    # claims stops at the claimed size rather than filling memory: one slice
    # holds at most a few blocks of at most 128 KB each.
    SLICE = 64

    private def decompress(frame, size)
      raise Invalid, "truncated character file" if frame.nil? || frame.bytesize.zero?

      stream = Zstd::StreamingDecompress.new
      payload = +""
      offset = 0
      while offset < frame.bytesize
        payload << stream.decompress(frame.byteslice(offset, SLICE))
        raise Invalid, "payload larger than its header says" if payload.bytesize > size

        offset += SLICE
      end
      raise Invalid, "payload size mismatch" if payload.bytesize != size

      payload.b
    rescue RuntimeError => e
      # zstd-ruby reports a corrupt frame as a bare RuntimeError.
      raise Invalid, "unreadable character file: #{e.message}"
    end

    # Face shape: four blends {head_id, value} per part, stored blend-major.
    private def dna(block)
      return if block.empty?
      raise Invalid, "truncated face block" if block.bytesize < 24

      # The hash is printed in stored byte order, the stamp as a number.
      gender = block.byteslice(4, 4).unpack1("H*")
      stamp = block.unpack1("@8V")
      part_count, blends, _, max_head_id = block.unpack("@16v4")
      raise Invalid, "truncated face block" if block.bytesize < 24 + (part_count * blends * 4)

      parts = Array.new(part_count) { [] }
      offset = 24
      blends.times do
        part_count.times do |part|
          value, head = block.unpack("@#{offset}vv")
          parts[part] << [head, value]
          offset += 4
        end
      end

      {
        "gender_hash" => gender,
        "stamp" => format("%08x", stamp),
        "part_count" => part_count,
        "max_head_id" => max_head_id,
        "parts" => parts
      }
    end

    # One port and its children; the last node's tail is the material count.
    private def node(ports)
      name = u32
      item = guid
      children = u32
      u32
      ports[NAMES.fetch(name) { format("0x%08x", name) }] = item
      children.times { node(ports) }
    end

    private def materials
      out = {}

      while left >= 4 && peek_u32 != 0
        name = u32
        material_guid = guid
        u32
        raw(16)
        count = u32
        raise Invalid, "unexpected sub-material header" unless u32 == 5

        subs = Array.new(count) do |index|
          sub = submaterial
          if index < count - 1
            raise Invalid, "unexpected sub-material separator" unless u32 == 5
          elsif left >= 4 && peek_u32 == 5
            u32
          end
          sub
        end

        out[NAMES.fetch(name) { format("0x%08x", name) }] = {"guid" => material_guid, "subs" => subs}
      end

      out
    end

    private def submaterial
      name = u32
      textures = Array.new(u32) do
        u32
        index = raw(1).ord
        [index, guid]
      end.to_h

      floats = Array.new(u64) do
        key = u32
        value = f32
        u32
        [named(key), value]
      end.to_h

      colors = {}
      ints = {}
      u64.times do
        key = named(u32)
        value = raw(4)
        u32
        if key.end_with?(*INT_SUFFIXES)
          ints[key] = value.unpack1("l<")
        else
          colors[key] = format("#%02x%02x%02x", *value.bytes.first(3))
        end
      end

      {"name" => format("0x%08x", name), "textures" => textures, "floats" => floats, "colors" => colors, "ints" => ints}
    end

    private def named(hash) = NAMES.fetch(hash) { format("0x%08x", hash) }

    # A CIG GUID prints bytes 7..0, then 15..8.
    private def guid
      hex = raw(16).bytes.then { |b| b[0, 8].reverse + b[8, 8].reverse }.map { |byte| format("%02x", byte) }.join
      "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}"
    end

    private def u32 = take(4).unpack1("V")

    private def u64 = take(8).unpack1("Q<")

    private def f32 = take(4).unpack1("e")

    private def raw(count) = take(count)

    private def peek_u32 = @bytes.byteslice(@offset, 4).unpack1("V")

    private def left = @bytes.bytesize - @offset

    private def take(count)
      raise Invalid, "truncated character file" if count > left

      value = @bytes.byteslice(@offset, count)
      @offset += count
      value
    end
  end
end
