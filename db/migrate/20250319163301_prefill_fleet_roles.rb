class PrefillFleetRoles < ActiveRecord::Migration[7.2]
  def up
    Fleet.find_each do |fleet|
      %i[admin officer member].each_with_index do |role, index|
        fleet.fleet_roles.create!(
          name: role.to_s.humanize,
          permanent: role == :admin,
          resource_access: FleetRole::DEFAULT_PRIVILEGES[role],
          rank: index + 1
        )
      end
    end

    FleetMembership.find_each do |membership|
      membership.update(fleet_role: membership.fleet.fleet_roles.find_by(slug: membership.role))
    end
  end
end

