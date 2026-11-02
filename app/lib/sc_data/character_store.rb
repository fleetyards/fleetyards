# frozen_string_literal: true

module ScData
  # The rigged base bodies sc-tools publishes under `characters/`. Unlike the
  # other render stores the index carries each body's file list itself:
  # `{"bodies" => {"male" => {"body" => "characters/male/body.glb",
  # "animations" => …, "files" => {"body.glb" => {"md5", "size"}}, "clips" => […]}}}`.
  class CharacterStore < RenderStore
    # "<key>" => {"path", "files", "clips", "weapon_in_hand"}, where "path" is
    # the folder the files sit in below the prefix, and "weapon_in_hand" the
    # hand bones with the fixed turn a weapon's holo needs to sit in them.
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
          "weapon_in_hand" => entry["weaponInHand"]
        }]
      end
    end

    # The customizer's light rigs, "<rig>" => {"lights" => [...]}: `review_<key>`
    # lights a body's whole outfit. Empty until the export lists them.
    def lighting_rigs(manifest = self.manifest)
      file = manifest.dig("lighting", "file")
      return {} if file.blank?

      read_json(file.delete_prefix("#{prefix}/")).fetch("rigs", {})
    end

    private def prefix
      "characters"
    end
  end
end
