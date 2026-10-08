# frozen_string_literal: true

# A linked player who held the fleet's Discord join role when it was last
# looked at. Membership follows changes to the role, not the role itself: a
# Discord member update arrives for any change, so without this a holder who
# left the fleet would be added back the next time they changed their nickname.
# == Schema Information
#
# Table name: fleet_discord_role_holders
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  fleet_id   :uuid             not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_fleet_discord_role_holders_on_fleet_id_and_user_id  (fleet_id,user_id) UNIQUE
#  index_fleet_discord_role_holders_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (user_id => users.id)
#
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
