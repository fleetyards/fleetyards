# frozen_string_literal: true

module ScData
  # The ship renders sc-tools publishes under `ship-views/`. A ship's listing
  # also carries its slug, path and whether it is a concept.
  class ShipViewsStore < RenderStore
    # "<manufacturer>/<slug>" => {"slug", "scKey", "files", "updatedAt"}, where
    # "scKey" is the game-file key, absent for a concept.
    def ships
      index.fetch("ships", {})
    end

    private def prefix
      "ship-views"
    end
  end
end
