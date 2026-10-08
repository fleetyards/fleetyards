# frozen_string_literal: true

# A linked player who held the fleet's Discord join role when it was last
# looked at. Membership follows changes to the role, not the role itself: a
# Discord member update arrives for any change, so without this a holder who
# left the fleet would be added back the next time they changed their nickname.
class FleetDiscordRoleHolder < ApplicationRecord
  belongs_to :fleet
  belongs_to :user

  # Whether this call is the one that recorded the role as held, so two events
  # racing for the same player admit them once.
  def self.remember(fleet, user)
    insert({fleet_id: fleet.id, user_id: user.id}, unique_by: %i[fleet_id user_id]).rows.any?
  end

  # Whether this call is the one that recorded the role as lost.
  def self.forget(fleet, user)
    where(fleet:, user:).delete_all.positive?
  end
end
