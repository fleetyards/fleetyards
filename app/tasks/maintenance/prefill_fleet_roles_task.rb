# frozen_string_literal: true

module Maintenance
  class PrefillFleetRolesTask < MaintenanceTasks::Task
    def collection
      Fleet.all
    end

    def process(fleet)
      fleet.setup_default_roles!

      fleet.fleet_memberships.where(fleet_role: nil).find_each do |membership|
        membership.update(fleet_role: fleet.fleet_roles.find_by(slug: membership.role))
      end
    end
  end
end
