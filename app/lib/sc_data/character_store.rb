# frozen_string_literal: true

module ScData
  # The base bodies sc-tools publishes under `characters/`, one folder per body
  # ("male/body.glb", "male/animations.glb").
  class CharacterStore < RenderStore
    # "<key>" => {"files", "updatedAt"}
    def characters
      index.fetch("characters", {})
    end

    private def prefix
      "characters"
    end
  end
end
