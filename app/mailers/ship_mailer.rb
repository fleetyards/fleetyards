# encoding: utf-8
# frozen_string_literal: true

class ShipMailer < ApplicationMailer
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def notify_admin(ship)
    @ship = ship
    mail(
      to: Rails.application.secrets[:mailer_admin_mail],
      subject: I18n.t(:"mailer.user.admin.subject"),
      template_name: 'admin'
    )
  end
end
