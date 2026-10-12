# frozen_string_literal: true

module Maintenance
  # Links every paint pledge a hangar sync stored before pledges were linked to
  # their catalogue paints. Re-runnable: a pledge's links are replaced, not
  # added to, so a second run after a name-map fix moves what the fix moved.
  class LinkHangarPledgePaintsTask < MaintenanceTasks::Task
    def collection
      HangarPledgeItem.paints.select(:id, :kind, :name).in_batches(of: HangarPledgeItems::PaintLinker::BATCH_SIZE)
    end

    def process(batch)
      linker.link(batch.to_a)
    end

    # The catalogue is read once for the whole run.
    private def linker
      @linker ||= HangarPledgeItems::PaintLinker.new
    end
  end
end
