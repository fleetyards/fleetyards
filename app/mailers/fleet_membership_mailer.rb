# frozen_string_literal: true

class FleetMembershipMailer < ApplicationMailer
  def new_invite(to, fleet)
    @fleet = fleet

    mail(
      to: to,
      subject: I18n.t(:"mailer.fleet_membership.new_invite.subject")
    )
  end
end
