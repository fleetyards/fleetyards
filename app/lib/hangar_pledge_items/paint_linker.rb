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

      ids = items.map(&:id)
      rows = items.flat_map do |item|
        @resolver.model_paint_ids(item.name).uniq.map do |model_paint_id|
          {hangar_pledge_item_id: item.id, model_paint_id:}
        end
      end

      replace(ids, rows)
    rescue ActiveRecord::InvalidForeignKey
      # A sync melted one of the pledges, or a paint was deleted, after they
      # were read: a backfill or relink reads its batch long before it writes.
      replace(ids, still_present(rows))
    end

    # In a savepoint, so a sync's own transaction outlives a failed write.
    private def replace(ids, rows)
      HangarPledgeItemModelPaint.transaction(requires_new: true) do
        HangarPledgeItemModelPaint.where(hangar_pledge_item_id: ids).delete_all
        HangarPledgeItemModelPaint.insert_all(rows) if rows.any?
      end
    end

    private def still_present(rows)
      items = HangarPledgeItem.where(id: rows.pluck(:hangar_pledge_item_id)).pluck(:id).to_set
      paints = ModelPaint.where(id: rows.pluck(:model_paint_id)).pluck(:id).to_set

      rows.select { |row| items.include?(row[:hangar_pledge_item_id]) && paints.include?(row[:model_paint_id]) }
    end
  end
end
