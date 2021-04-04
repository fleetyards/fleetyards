class SetInitialStateForFleetMemberships < ActiveRecord::Migration[6.1]
  def up
    FleetMembership.find_each do |member|
      if member.accepted_at.present?
        member.update(aasm_state: :accepted, invited_at: member.created_at)
      elsif member.declined_at.present?
        member.update(aasm_state: :declined, invited_at: member.created_at)
      else
        member.update(aasm_state: :invited, invited_at: member.created_at)
      end
    end
  end
end
