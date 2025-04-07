class PrefillFleetRoles < ActiveRecord::Migration[7.2]
  def up
    Fleet.find_each do |fleet|
      puts fleet.id
      fleet.setup_default_roles!
    end

    FleetMembership.find_each do |membership|
      membership.update(fleet_role: membership.fleet.fleet_roles.find_by(slug: membership.role))
    end
  end
end
