# frozen_string_literal: true

require "test_helper"

module Chf
  class ResolverTest < ActiveSupport::TestCase
    FIXTURES = Rails.root.join("test/fixtures/chf")
    CATALOG = JSON.parse(FIXTURES.join("catalog.json").read).freeze
    LIBRARIES = %w[male female].index_with { |body| JSON.parse(FIXTURES.join("#{body}_faces_index.json").read) }.freeze
    SKIN_TONES = {"male" => "#513428", "female" => "#cca089"}.freeze

    private def resolve(name, worn: [])
      Resolver.new(Reader.read(FIXTURES.join("#{name}.chf").binread), catalog: CATALOG, libraries: LIBRARIES, skin_tones: SKIN_TONES, worn:).spec
    end

    private def differences(got, expected, path = "", out = [])
      case [got, expected]
      in [Hash, Hash]
        (got.keys | expected.keys).each { |key| differences(got[key], expected[key], "#{path}/#{key}", out) }
      in [Array, Array] if got.size == expected.size
        got.each_with_index { |value, index| differences(value, expected[index], "#{path}/#{index}", out) }
      in [Numeric, Numeric]
        out << "#{path}: #{got} vs #{expected}" if (got - expected).abs > 1e-5
      else
        out << "#{path}: #{got.inspect} vs #{expected.inspect}" unless got == expected
      end
      out
    end

    test "resolves every test vector to what the reference resolves, worn headwear included" do
      FIXTURES.glob("*.character.json").each do |path|
        name, worn = path.basename(".character.json").to_s.split("__")
        got = resolve(name, worn: [worn].compact)
        got["meshes"].each { |mesh| mesh.delete("headwear") }
        got.delete("headwear_order")

        assert_empty differences(got, JSON.parse(path.read)), path.basename.to_s
      end
    end

    test "lists each hair and beard mesh's headwear variants exactly as wearing that headwear resolves them" do
      FIXTURES.glob("*__*.character.json").each do |path|
        name, worn = path.basename(".character.json").to_s.split("__")
        bare = resolve(name).fetch("meshes").index_by { |mesh| mesh["port"] }

        resolve(name, worn: [worn]).fetch("meshes").select { |mesh| mesh["headwear_variant"] }.each do |mesh|
          variant = bare.dig(mesh["port"], "headwear", mesh["headwear_variant"])

          assert_equal mesh.slice("url", "materials_by_submaterial"), variant, "#{name} #{worn} #{mesh["port"]}"
        end
      end
    end

    test "says in which order worn headwear picks a hair variant" do
      assert_equal %w[snoopy_cap hatHair_mask hatHair], resolve("Macken")["headwear_order"]
    end

    test "lists headwear variants only for hair, beard and stubble" do
      ports = resolve("Stows_Face").fetch("meshes").select { |mesh| mesh.key?("headwear") }.pluck("port")

      assert_not_empty ports
      assert_empty ports - Resolver::HEADWEAR_PORTS
    end

    test "takes the body from the face block, and from the body tag for a preset without one" do
      assert_equal "male", resolve("Macken")["body"]
      assert_equal "female", resolve("meg")["body"]
      assert_equal "male", resolve("regen_boss_hair_color")["body"]
      assert_nil resolve("regen_boss_hair_color").dig("face", "weights")
    end

    # The face library's synthetic vector: an absent head (19), an id past the
    # library (250), an all-zero part, a repeated id and small values.
    test "skips blends without a value, past the library or of an absent head, and renormalises the rest" do
      parts = {
        "EyebrowLeft" => [[19, 40000], [27, 20000]], "EyebrowRight" => [[0, 0], [0, 0]], "EyeLeft" => [[250, 65535]],
        "EyeRight" => [[5, 30000], [6, 30000], [5, 5535]], "Nose" => [[13, 1000], [36, 1000]],
        "EarLeft" => [[39, 65535]], "EarRight" => [[39, 65535]], "CheekLeft" => [[25, 65535]], "CheekRight" => [[25, 65535]],
        "Mouth" => [[2, 65535]], "Jaw" => [[12, 65535]], "Crown" => [[60, 65535]]
      }
      chf = {
        "format_version" => 7, "body_tag" => "25f439d5", "ports" => {}, "materials" => {},
        "dna" => {"gender_hash" => Resolver::MALE, "stamp" => "6a268db0", "part_count" => 12, "parts" => parts.values}
      }

      weights = Resolver.new(chf, catalog: CATALOG, libraries: LIBRARIES, skin_tones: SKIN_TONES).spec.dig("face", "weights")

      assert_equal({
        "EyebrowLeft" => [[27, 1.0]], "EyebrowRight" => [[0, 1.0]], "EyeLeft" => [[0, 1.0]],
        "EyeRight" => [[5, 0.457771], [6, 0.457771], [5, 0.084459]], "Nose" => [[13, 0.5], [36, 0.5]],
        "EarLeft" => [[39, 1.0]], "EarRight" => [[39, 1.0]], "CheekLeft" => [[25, 1.0]], "CheekRight" => [[25, 1.0]],
        "Mouth" => [[2, 1.0]], "Jaw" => [[12, 1.0]], "Crown" => [[60, 1.0]], "Neck" => [[0, 1.0]]
      }, weights.to_h { |part| [part["part"], part["heads"]] })
    end

    test "leaves the head as painted when the catalogue has no skin for the body" do
      spec = Resolver.new(Reader.read(FIXTURES.join("Macken.chf").binread), catalog: CATALOG.except("skins"), libraries: LIBRARIES, skin_tones: SKIN_TONES).spec

      assert_nil spec.dig("skin", "head", "base")
      assert_equal [1, 1, 1], spec.dig("skin", "head", "tone_gain")
    end

    test "gives a 12-part file's neck to the protos head" do
      assert_equal({"part" => "Neck", "heads" => [[0, 1.0]]}, resolve("Macken").dig("face", "weights").last)
    end

    test "recolours the body against the tone its textured holo is baked at" do
      spec = Resolver.new(Reader.read(FIXTURES.join("Macken.chf").binread), catalog: CATALOG, libraries: LIBRARIES, skin_tones: {"male" => spec_tone("Macken")}).spec

      assert_equal [1.0, 1.0, 1.0], spec.dig("skin", "body_baseColorFactor")
    end

    private def spec_tone(name) = resolve(name).dig("skin", "tone")
  end
end
