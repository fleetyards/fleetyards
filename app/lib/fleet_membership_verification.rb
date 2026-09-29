# frozen_string_literal: true

# A membership is verified when its user's handle is proved and their stored
# list of RSI orgs names the SID the fleet gives. The list is the record; the
# flag is recomputed from it wherever one of the two sides changes, and none of
# that asks RSI anything.
class FleetMembershipVerification
  def self.verified?(user, fleet)
    user.rsi_handle_verified? && fleet.rsi_sid.present? && user.rsi_organization_sids.include?(fleet.rsi_sid)
  end

  # After a user's list was written, or their handle stopped being proved.
  def self.sync_user(user)
    sync(user.fleet_memberships.kept.includes(:fleet, :user))
  end

  # After a fleet's SID changed: its members' lists answer for the new one.
  def self.sync_fleet(fleet)
    sync(fleet.fleet_memberships.kept.includes(:fleet, :user))
  end

  # Only a flag that changes is written, through the model, so the rosters
  # showing it hear of it and nothing else is broadcast.
  def self.sync(memberships)
    memberships.find_each do |membership|
      verified = verified?(membership.user, membership.fleet)
      next if membership.verified? == verified

      membership.update!(verified:)
    end
  end
end
