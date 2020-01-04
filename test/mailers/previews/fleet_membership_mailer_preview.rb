# frozen_string_literal: true

class FleetMembershipMailerPreview < ActionMailer::Preview
  def new_invite
    FleetMembershipMailer.new_invite('foo@bar.de', Fleet.first)
  end
end
