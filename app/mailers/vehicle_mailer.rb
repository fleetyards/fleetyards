# frozen_string_literal: true

class VehicleMailer < ApplicationMailer
  def on_sale(vehicle)
    @username = vehicle.user.username
    @vehicle = vehicle

    mail(
      to: vehicle.user.email,
      subject: I18n.t(:"mailer.vehicle.on_sale.subject", model: vehicle.model.name)
    )
  end
end
