# frozen_string_literal: true

module ScData
  # The component and equipment renders sc-tools publishes under `item-views/`.
  class ItemViewsStore < RenderStore
    # "<path>" => {"scKey", "files", "updatedAt"}, where "scKey" is the
    # game-file key of a component or a piece of equipment.
    def items
      index.fetch("items", {})
    end

    private def prefix
      "item-views"
    end
  end
end
