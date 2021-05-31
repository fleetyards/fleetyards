class FixAssmTimestampsForFleetMemberships < ActiveRecord::Migration[6.1]
  def up
    FleetMembership.find_each do |fleet_member|
      case fleet_member.aasm_state
      when 'invited'
        next if fleet_member.invited_at.present?

        fleet_member.update(invited_at: fleet_member.updated_at)
      when 'requested'
        next if fleet_member.requested_at.present?

        fleet_member.update(requested_at: fleet_member.updated_at)
      when 'accepted'
        next if fleet_member.accepted_at.present?

        fleet_member.update(accepted_at: fleet_member.updated_at)
      when 'declined'
        next if fleet_member.declined_at.present?

        fleet_member.update(declined_at: fleet_member.updated_at)
      end
    end
  end

  def down
  end
end
