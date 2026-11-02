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
    def characters
      index.fetch("bodies", {}).to_h do |key, entry|
        folder = File.dirname(entry.fetch("body", "#{prefix}/#{key}/body.glb")).delete_prefix("#{prefix}/")

        [key, {
          "path" => folder,
          "files" => entry.fetch("files", {}),
          "clips" => entry.fetch("clips", []),
          "weapon_in_hand" => entry["weaponInHand"]
        }]
      end
    end

    private def prefix
      "characters"
    end
  end
end
