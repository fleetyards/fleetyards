# frozen_string_literal: true

module Chf
  # Resolves a read character file against the customizer catalogue into
  # everything a viewer loads and sets: the face blend weights, the head skin
  # and its composite recipe, the eyes, and each equipped accessory with a
  # three.js material per sub-material. Asset paths stay bucket paths.
  #
  # `worn` takes the sc_keys of worn headwear, which hides or swaps hair the
  # way the game does. Each hair, beard and stubble mesh also lists every
  # headwear variant it has, resolved, so a viewer can apply worn items
  # itself without asking again.
  class Resolver
    VERSION = 3

    MALE = "f6676cdd"
    FEMALE = "54ebf49e"
    FEMALE_TAG = "d0794a94"

    PARTS = %w[EyebrowLeft EyebrowRight EyeLeft EyeRight Nose EarLeft EarRight CheekLeft CheekRight Mouth Jaw Crown Neck].freeze
    FIXED_PORTS = %w[body_itemport head_itemport eyes_itemport].freeze
    HEADWEAR_PORTS = %w[hair_itemport beard_itemport stubble_itemport].freeze
    HAIR_MODES = %w[hair_cards hair_coat hair_cap].freeze
    GAME_PARAMS = %w[
      BaseMelanin BaseMelaninRedness BaseMelaninVariation DyeAmount DyeColor DyeFadeout DyeShift
      DyePigmentVariation BaseTintColor Smoothness
    ].freeze
    SCLERA = "#d9d0c8"
    DEFAULT_IRIS = "#272727"
    EYE_RULE = "lin(out) = lerp(lin(sclera), lin(tex.rgb) * lin(iris_color) * 1.6, tex.a)"
    VARIATION_RULE = "color *= 1 + amount * (id - 0.5)"

    # Hair melanin: absorption as in d'Eon/Chiang, scaled so the authored NPC
    # hair the customizer offers comes out the colour it is in the game.
    EUMELANIN = [0.506, 0.841, 1.653].freeze
    PHEOMELANIN = [0.343, 0.733, 1.924].freeze
    ABSORPTION_SCALE = 0.3
    REC709 = [0.2126, 0.7152, 0.0722].freeze
    DYE_LIFT_LUMINANCE = 0.1
    BETA = 0.3
    ABSORPTION_DEPTH = 5.969 - (0.215 * BETA) + (2.532 * (BETA**2)) - (10.73 * (BETA**3)) + (5.574 * (BETA**4)) + (0.245 * (BETA**5))

    # chf: Chf::Reader output. catalog: catalog.json. libraries: body =>
    # the face library's index.json. skin_tones: body => the tone its
    # textured holo is baked at.
    def initialize(chf, catalog:, libraries:, skin_tones:, worn: [])
      @chf = chf
      @catalog = catalog
      @libraries = libraries
      @skin_tones = skin_tones
      @worn = worn.map(&:downcase)
    end

    def body
      @body ||= case dna&.dig("gender_hash")
      when FEMALE then "female"
      when MALE then "male"
      else @chf["body_tag"].start_with?(FEMALE_TAG) ? "female" : "male"
      end
    end

    def library = @libraries.fetch(body)

    def spec
      tags, hidden = headwear

      {
        "format" => "sc-chf-character",
        "version" => VERSION,
        "source" => source,
        "body" => body,
        "assets" => {
          "body_glb" => "characters/#{body}/body_textured.glb",
          "faces" => "characters/#{body}/faces/index.json",
          "catalog" => "characters/chf/catalog.json"
        },
        "face" => {"weights" => face_weights},
        "skin" => {"tone" => skin_tone, "body_baseColorFactor" => body_color_factor, "head" => head_recipe},
        "eyes" => eye_recipe,
        "meshes" => meshes(tags, hidden),
        "worn" => {
          "items" => @worn,
          "tags" => tags.sort,
          "hidden_ports" => hidden.sort,
          "fit" => @worn.index_with { |key| @catalog.dig("headwear_items", key, "fit") || "rigid" }
        },
        "hidden_parts" => @catalog["hidden_parts"],
        "headwear_order" => variant_order("hair_itemport"),
        "unresolved_ports" => @chf["ports"].reject { |port, item| FIXED_PORTS.include?(port) || catalog_item(item) }
      }
    end

    private def dna = @chf["dna"]

    private def source
      {
        "format_version" => @chf["format_version"],
        "dna_stamp" => dna&.dig("stamp"),
        "gender_hash" => dna&.dig("gender_hash"),
        "part_count" => dna&.dig("part_count") || 0,
        "face_library" => library["library"],
        "library_stamp_ok" => dna && (dna["stamp"].to_i(16) <= library.dig("dna", "stamp").to_s.to_i(16))
      }
    end

    # Per part the usable blends, normalised: a blend counts with a value, a
    # head id inside the library and a head that exists. A part with none
    # left takes the protos head, as does the neck of a 12-part file.
    private def face_weights
      return unless dna

      heads = library["heads"]
      count = library["head_count"]

      PARTS.each_with_index.map do |part, index|
        blends = (dna["parts"][index] || []).select { |head, value| value.positive? && head < count && heads.dig(head, "available") }
        total = blends.sum(&:last).to_f
        weights = total.positive? ? blends.map { |head, value| [head, (value / total).round(6)] } : [[0, 1.0]]
        {"part" => part, "heads" => weights}
      end
    end

    private def material(name)
      @chf.dig("materials", name, "subs")&.first
    end

    private def catalog_item(guid)
      item = @catalog.dig("items", guid)
      item if item&.dig("bodies", body)
    end

    private def items
      @chf["ports"].filter_map { |port, guid| (item = catalog_item(guid)) && [port, guid, item] }.sort_by { |port, guid, _| [port, guid] }
    end

    private def headwear
      table = @catalog.fetch("headwear_items", {})
      parts = @catalog.fetch("hidden_parts", {}).transform_keys(&:downcase)
      tags = Set.new
      hidden = Set.new

      @worn.each do |key|
        item = table[key] or next
        tags << item["hairTag"] if item["hairTag"]
        tags.merge(item["addsTags"] || [])
        tags << "maskFacialHair" if item["maskFacialHair"]
        (item["hiddenParts"] || []).each { |part| hidden.merge(parts.fetch(part.downcase, [])) }
      end

      [tags.to_a, hidden.to_a]
    end

    private def variant_order(port)
      case port
      when "hair_itemport" then @catalog.dig("headwear_rule", "order") || []
      when "beard_itemport", "stubble_itemport" then ["maskFacialHair"]
      else []
      end
    end

    private def meshes(tags, hidden)
      hair = items.find { |port, _, _| port == "hair_itemport" }&.last

      items.filter_map do |port, guid, item|
        next if hidden.include?(port)

        entry = item.dig("bodies", body)
        variants = entry["headwear"] || {}
        tag = variant_order(port).find { |candidate| tags.include?(candidate) && variants.key?(candidate) }
        chosen = tag ? variants[tag] : entry

        mesh = {
          "port" => port,
          "item" => guid,
          "record" => item["record"],
          "kind" => item["kind"],
          "url" => chosen["geometry"],
          "headwear_variant" => tag,
          "deform" => "head_binding",
          "materials_by_submaterial" => primitives(port, chosen["submaterials"], hair)
        }

        if HEADWEAR_PORTS.include?(port) && variants.any?
          mesh["headwear"] = variants.slice(*variant_order(port)).transform_values do |variant|
            {"url" => variant["geometry"], "materials_by_submaterial" => primitives(port, variant["submaterials"], hair)}
          end
        end

        mesh
      end
    end

    private def primitives(port, templates, hair)
      templates.each_with_index.map do |template, index|
        next {"submaterial" => index, "material" => {"name" => template["name"], "mode" => "cloth", "three" => three(template["three"])}} if template["mode"] == "cloth"

        scalp_of = nil
        if port == "universal_scalp_itemport" && template["name"] == "hair_scalp_m"
          cap = hair&.dig("bodies", body, "scalp")
          next {"submaterial" => index, "visible" => false} unless cap

          template = scalp_of = cap
        end

        {"submaterial" => index, "material" => three_material(port, template, scalp_of)}
      end
    end

    private def three(params) = {"type" => "MeshStandardMaterial"}.merge(params || {})

    private def three_material(port, template, scalp_of)
      mode = template["mode"]
      out = {"name" => template["name"], "mode" => mode}

      case mode
      when *HAIR_MODES
        params = hair_params(port, scalp_of || template)
        color = hair_color(params)
        textures = template["textures"] || {}

        if mode == "hair_cap"
          out["three"] = three(
            "color" => color.map { |c| (c * 0.8).round(5) }, "alphaMap" => textures["coverage"], "texCoord" => 0, "transparent" => true,
            "depthWrite" => false, "opacity" => 1.0, "roughness" => 0.9, "metalness" => 0.0,
            "polygonOffset" => true, "polygonOffsetFactor" => -1
          )
        else
          # Without an anisotropic hair lobe the raw 1 - Smoothness reads as a
          # white sheen; the specular takes the hair's own hue at half strength.
          brightest = [color.max, 1e-6].max
          out["three"] = three(
            "type" => "MeshPhysicalMaterial",
            "color" => color.map { |c| c.round(5) }, "alphaMap" => textures["alpha"], "texCoord" => 0,
            "alphaTest" => (mode == "hair_cards") ? 0.33 : 0.15, "alphaToCoverage" => true,
            "alphaMipScale" => opacity_mip_scale(scalp_of || template, mode).round(4), "transparent" => false,
            "side" => "DoubleSide", "roughness" => (1 - (0.6 * params.fetch("Smoothness", 0.6))).clamp(0.55, 0.85).round(4),
            "metalness" => 0.0, "specularIntensity" => 0.5, "specularColor" => color.map { |c| (c / brightest).round(4) }
          )
          if textures["id"]
            out["variation"] = {"map" => textures["id"], "texCoord" => 0, "amount" => params.fetch("BaseMelaninVariation", 0.0).to_f, "rule" => VARIATION_RULE}
          end
        end
        out["game"] = params.slice(*GAME_PARAMS)
      when "hair_legacy"
        out["three"] = three(
          "map" => template.dig("textures", "diffuse"), "color" => template["diffuse"] || [1, 1, 1],
          "alphaTest" => 0.4, "side" => "DoubleSide", "roughness" => 0.5, "metalness" => 0.0
        )
      when "metal"
        out["three"] = three(template["three"])
      else
        out["three"] = three("color" => [0.5, 0.5, 0.5], "roughness" => 0.6, "metalness" => 0.0)
      end

      out
    end

    # The game scales strand opacity per mip level, without which thin strands
    # vanish once the texture is minified: at least 1, and 2.5 for cards that
    # do not say.
    private def opacity_mip_scale(template, mode)
      scale = template.dig("params", "OpacityMipScale")
      return [scale.to_f, 1.0].max if scale.is_a?(Numeric) && scale.nonzero?

      (mode == "hair_cards") ? 2.5 : 1.0
    end

    # The template's parameters, overridden by what the character file says
    # for the port's dye material.
    private def hair_params(port, template)
      params = (template["params"] || {}).dup
      dye = @catalog.dig("ports", port, "dye_material")
      sub = dye && material(dye)
      return params unless sub

      params.merge!(sub["floats"])
      params["DyeColor"] = self.class.hex_linear(sub["colors"]["HairDyeColor1"]) if sub["colors"]["HairDyeColor1"]
      params["BaseTintColor"] = self.class.hex_linear(sub["colors"]["HairDyeColor2"]) if sub["colors"]["HairDyeColor2"]
      params
    end

    private def hair_color(params)
      base = melanin_color(params.fetch("BaseMelanin", 0.5), params.fetch("BaseMelaninRedness", 0.0))
      dye = params.fetch("DyeColor", [1, 1, 1])
      amount = params.fetch("DyeAmount", 0.0) * (1 - (0.5 * params.fetch("DyeFadeout", 0.0)))
      tint = params.fetch("BaseTintColor", [1, 1, 1])

      # A dye lighter than the hair lifts it only as far as its own luminance
      # allows: a dark dye cannot cover darker hair.
      dye_luminance = luminance(dye)
      amount *= [1.0, dye_luminance / DYE_LIFT_LUMINANCE].min if dye_luminance > luminance(base)

      3.times.map do |c|
        mixed = (self.class.linear_srgb(base[c]) * (1 - amount)) + (self.class.linear_srgb(dye[c]) * amount)
        (self.class.srgb_linear(mixed) * tint[c]).clamp(0.0, 1.0)
      end
    end

    private def luminance(color) = color.zip(REC709).sum { |c, y| c * y }

    private def melanin_color(melanin, redness)
      m = -Math.log([1.0 - melanin.clamp(0.0, 1.0), 1e-4].max)
      eu = m * (1 - redness)
      ph = m * redness

      3.times.map do |c|
        absorption = ((eu * EUMELANIN[c]) + (ph * PHEOMELANIN[c])) * ABSORPTION_SCALE
        Math.exp(-Math.sqrt([absorption, 0].max) * ABSORPTION_DEPTH)
      end
    end

    private def skin_tone
      head = material("Head Material")
      return head["colors"]["BodyColor"] if head&.dig("colors", "BodyColor")

      material("BodyMaterial")&.dig("colors", "BodyColor")
    end

    # A head material the catalogue does not know shows the first skin set of
    # the body.
    # A catalogue with no skin for the body at all leaves the head as painted.
    private def head_skin
      skins = @catalog.fetch("skins", {})
      guid = @chf.dig("materials", "Head Material", "guid")
      skins[guid] || skins.values.find { |skin| skin["body"] == body } || {}
    end

    private def head_recipe
      skin = head_skin
      tone = skin_tone
      average = skin["SourceAverageColor"]
      gain = (tone && average) ? self.class.hex_linear(tone).zip(average).map { |l, s| (l / s).round(5) } : [1, 1, 1]
      head = material("Head Material") || {"floats" => {}, "colors" => {}, "textures" => {}, "ints" => {}}
      floats = head["floats"]
      colors = head["colors"]
      textures = head["textures"]
      url = ->(slot) { @catalog.dig("textures", textures[slot].to_s, "url") }
      layers = []

      if url.call(4) && url.call(9)
        layers << {
          "type" => "blemish", "mask" => url.call(4), "id" => url.call(9),
          "freckles" => {"amount" => floats.fetch("FrecklesAmount", 0), "opacity" => floats.fetch("FrecklesOpacity", 0), "channel" => 0, "darken" => 0.55},
          "sunspots" => {"amount" => floats.fetch("SunSpotsAmount", 0), "opacity" => floats.fetch("SunSpotsOpacity", 0), "channel" => 1, "darken" => 0.75}
        }
      end

      [[1, 12, "EyeMakeupColor"], [2, 13, "CheekMakeupColor"], [3, 14, "LipMakeupColor"]].each do |slot, index, prefix|
        next unless url.call(index)

        opacity = floats.fetch("Makeup#{slot}Opacity", 1.0)
        channels = %w[R G B].each_with_index.map do |channel, k|
          {
            "color" => colors.fetch("#{prefix}#{k + 1}", "#000000"),
            "opacity" => floats.fetch("Makeup#{slot}Opacity#{channel}", 1.0) * opacity,
            "metalness" => floats.fetch("Makeup#{slot}Metalness#{channel}", 0.0),
            "smoothness" => floats.fetch("Makeup#{slot}Smoothness#{channel}", 0.5)
          }
        end
        layers << {
          "type" => "makeup", "slot" => slot, "texture" => url.call(index), "channels" => channels,
          "tiles" => [head["ints"].fetch("Makeup#{slot}NumTilesU", 8), head["ints"].fetch("Makeup#{slot}NumTilesV", 8)],
          "offset" => [head["ints"].fetch("Makeup#{slot}OffsetU", 0), head["ints"].fetch("Makeup#{slot}OffsetV", 0)]
        }
      end

      if url.call(8)
        layers << {
          "type" => "tattoo", "texture" => url.call(8), "blend" => @catalog.dig("textures", textures[8], "blend") || "alpha",
          "age" => floats.fetch("TattooAge", 0.0), "hue" => floats.fetch("TattooHueRotation", 0.0)
        }
      end

      {"base" => skin["base"], "tone_gain" => gain, "layers" => layers, "normal" => skin["normal"], "orm" => skin["orm"], "skin_set" => skin["mtl"]}
    end

    private def eye_recipe
      {"iris" => @catalog.dig("eye", "iris"), "iris_color" => material("EyeMaterial")&.dig("colors", "EyeColor") || DEFAULT_IRIS, "sclera" => SCLERA, "rule" => EYE_RULE}
    end

    private def body_color_factor
      tone = skin_tone
      current = @skin_tones[body]
      return [1, 1, 1] unless tone && current

      self.class.hex_linear(tone).zip(self.class.hex_linear(current)).map { |t, c| (t / c).round(5) }
    end

    def self.srgb_linear(c) = (c <= 0.04045) ? c / 12.92 : ((c + 0.055) / 1.055)**2.4

    def self.linear_srgb(c)
      c = c.clamp(0.0, 1.0)
      (c <= 0.0031308) ? c * 12.92 : (1.055 * (c**(1 / 2.4))) - 0.055
    end

    def self.hex_linear(hex) = [1, 3, 5].map { |i| srgb_linear(hex[i, 2].to_i(16) / 255.0) }
  end
end
