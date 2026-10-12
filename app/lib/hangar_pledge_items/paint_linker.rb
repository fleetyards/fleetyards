# frozen_string_literal: true

module HangarPledgeItems
  # Writes down which catalogue paints the given paint pledges are, replacing
  # whatever they were linked to before: a renamed catalogue paint or a fixed
  # name map can move a pledge.
  class PaintLinker
    def initialize(resolver: PaintResolver.new)
      @resolver = resolver
    end

    BATCH_SIZE = 1_000

    # Every paint pledge, for when the catalogue itself changed.
    def link_all
      HangarPledgeItem.paints.select(:id, :kind, :name).find_in_batches(batch_size: BATCH_SIZE) do |items|
        link(items)
      end
    end

    def link(items)
      items = items.select { |item| item.kind == "paint" }
      return if items.empty?

      rows = items.flat_map do |item|
        @resolver.model_paint_ids(item.name).uniq.map do |model_paint_id|
          {hangar_pledge_item_id: item.id, model_paint_id:}
        end
      end

      HangarPledgeItemModelPaint.transaction do
        HangarPledgeItemModelPaint.where(hangar_pledge_item_id: items.map(&:id)).delete_all
        HangarPledgeItemModelPaint.insert_all(rows) if rows.any?
      end
    end
  end
end
