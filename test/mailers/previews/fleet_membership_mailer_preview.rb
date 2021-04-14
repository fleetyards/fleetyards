# frozen_string_literal: true

class FleetMembershipMailerPreview < ActionMailer::Preview
  def new_invite
    FleetMembershipMailer.new_invite('foo@bar.de', User.first.username, Fleet.first)
  end

  def member_requested
    FleetMembershipMailer.member_requested(['foo@bar.de', 'bar@foo.de'], User.first.username, Fleet.first)
  end

  def fleet_accepted
    FleetMembershipMailer.fleet_accepted('foo@bar.de', User.first.username, Fleet.first)
  end

  def member_accepted
    FleetMembershipMailer.member_accepted(['foo@bar.de', 'bar@foo.de'], User.first.username, Fleet.first)
  end
end
