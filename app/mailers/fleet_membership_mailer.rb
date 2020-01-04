# frozen_string_literal: true

class FleetMembershipMailer < ApplicationMailer
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def new_invite(to, fleet)
    @fleet = fleet
    mail(
      to: to,
      subject: I18n.t(:"mailer.fleet_membership.new_invite.subject")
    )
  end
end
