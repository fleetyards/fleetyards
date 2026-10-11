# frozen_string_literal: true

module Maintenance
  # Rebuilds the fleet entries of every membership that shares ships by hangar
  # group, from the hangar as it is now.
  #
  # Two group changes used to leave those entries behind. A hangar sync filing
  # ships into a group inserted its task forces in bulk, so neither the ships nor
  # their loaners were ever revisited. And a task force only touched its own
  # vehicle, while a loaner is listed by its parent's groups. Those loaners were
  # corrected by the weekly loaner sync; the synced ships never were.
  #
  # Memberships sharing everything or nothing do not read groups, so they are
  # left out. Re-runnable: `update_fleet_vehicles` converges on the hangar.
  class RefreshHangarGroupFleetVehiclesTask < MaintenanceTasks::Task
    def collection
      FleetMembership.kept.accepted.where(ships_filter: "hangar_group")
    end

    def count
      collection.count
    end

    def process(membership)
      membership.update_fleet_vehicles
    end
  end
end
