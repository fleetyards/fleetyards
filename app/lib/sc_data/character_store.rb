# frozen_string_literal: true

module ScData
  # The rigged base bodies sc-tools publishes under `characters/`. Unlike the
  # other render stores the index carries each body's file list itself:
  # `{"bodies" => {"male" => {"body" => "characters/male/body.glb",
  # "animations" => …, "files" => {"body.glb" => {"md5", "size"}}, "clips" => […]}}}`.
  class CharacterStore < RenderStore
    # "<key>" => {"path", "files", "clips", "weapon_in_hand", "hold_poses",
    # "skin_tone", "faces"}, where "path" is the folder the files sit in below
    # the prefix, "weapon_in_hand" the hand bones with the fixed turn a
    # weapon's holo needs to sit in them, "hold_poses" the hold clips per
    # weapon, stance and armour weight, "skin_tone" the tone the textured body is
    # baked at, and "faces" the face library: {"path", "library", "files"}, or
    # nil.
    # The index itself, for a caller that reads both the bodies and the
    # lighting from one fetch of it.
    def manifest = index

    def characters(manifest = self.manifest)
      manifest.fetch("bodies", {}).to_h do |key, entry|
        folder = File.dirname(entry.fetch("body", "#{prefix}/#{key}/body.glb")).delete_prefix("#{prefix}/")

        [key, {
          "path" => folder,
          "files" => entry.fetch("files", {}),
          "clips" => entry.fetch("clips", []),
          "weapon_in_hand" => entry["weaponInHand"],
          "hold_poses" => entry["holdPoses"],
          "skin_tone" => entry.dig("skin", "tone"),
          "faces" => faces(entry["faces"]),
          "default_character" => default_character(entry["defaultCharacter"])
        }]
      end
    end

    # Every file a resolved character file can name: the item catalogue, the
    # per-body geometry and skin sets, and the shared hair, makeup, tattoo,
    # blemish and eye textures. The specs, reference scripts and test vectors
    # beside them are not served.
    ASSET = %r{\A(?:chf/(?:catalog\.json|textures/.+\.webp)|[a-z]+/chf/(?:index\.json|geometry/[^/]+\.glb|skin/[^/]+\.webp))\z}

    # "<path below the prefix>" => RemoteObject.
    def assets = remote_objects.select { |path, _| path.match?(ASSET) }

    # The customizer's light rigs, "<rig>" => {"lights" => [...]}: `review_<key>`
    # lights a body's whole outfit. Empty until the export lists them.
    def lighting_rigs(manifest = self.manifest)
      file = manifest.dig("lighting", "file")
      return {} if file.blank?

      read_json(file.delete_prefix("#{prefix}/")).fetch("rigs", {})
    end

    # The game's default character: {"path", "files"}, or nil.
    private def default_character(entry)
      return unless entry.is_a?(Hash) && entry["chf"].is_a?(String) && entry["files"].is_a?(Hash)

      {"path" => File.dirname(entry["chf"]).delete_prefix("#{prefix}/"), "files" => entry["files"]}
    end

    private def faces(entry)
      return unless entry.is_a?(Hash) && entry["path"].is_a?(String) && entry["library"].is_a?(String)

      {
        "path" => entry["path"].delete_prefix("#{prefix}/").delete_suffix("/"),
        "library" => entry["library"],
        "files" => entry.fetch("files", {})
      }
    end

    private def prefix
      "characters"
    end
  end
end
