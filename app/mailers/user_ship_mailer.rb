# encoding: utf-8
# frozen_string_literal: true

class UserShipMailer < ActionMailer::Base
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def on_sale(user_ship)
    @user_ship = user_ship
    mail(
      to: user_ship.user.email,
      subject: I18n.t(:"mailer.user_ship.on_sale.subject", ship: user_ship.ship.name)
    )
  end
end
