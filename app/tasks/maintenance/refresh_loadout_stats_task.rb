# frozen_string_literal: true

module Maintenance
  # Works out the guns of every ship and every saved loadout in each source a
  # reader can pick, as the refresh after a load does. For a database whose
  # stats predate a load, or were never written.
  #
  # Re-runnable: each run replaces what the last one wrote.
  class RefreshLoadoutStatsTask < MaintenanceTasks::Task
    def collection
      ::ScData::Source.available
    end

    def process(source)
      LoadoutStat.refresh(source)
    end
  end
end
