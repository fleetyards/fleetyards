# frozen_string_literal: true

module ScData
  # The component and equipment renders sc-tools publishes under `item-views/`.
  class ItemViewsStore < RenderStore
    # "<path>" => {"scKey", "files", "updatedAt"}, where "scKey" is the
    # game-file key of a component or a piece of equipment. The published index
    # names an item by its folder alone, which is that key.
    def items
      index.fetch("items", {}).to_h { |path, entry| [path, {"scKey" => path}.merge(entry)] }
    end

    private def prefix
      "item-views"
    end
  end
end
