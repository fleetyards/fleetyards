# frozen_string_literal: true

class FleetMembershipMailer < ApplicationMailer
  def new_invite(to, username, fleet)
    @username = username
    @fleet = fleet

    mail(
      to: to,
      subject: I18n.t(:'mailer.fleet_membership.new_invite.subject')
    )
  end

  def member_requested(to, member_username, fleet)
    @member_username = member_username
    @fleet = fleet

    mail(
      to: to,
      subject: I18n.t(:'mailer.fleet_membership.member_requested.subject')
    )
  end

  def member_accepted(to, member_username, fleet)
    @member_username = member_username
    @fleet = fleet

    mail(
      to: to,
      subject: I18n.t(:'mailer.fleet_membership.member_accepted.subject')
    )
  end

  def fleet_accepted(to, username, fleet)
    @username = username
    @fleet = fleet

    mail(
      to: to,
      subject: I18n.t(:'mailer.fleet_membership.fleet_accepted.subject', fleet: fleet.name)
    )
  end
end
