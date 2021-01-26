# frozen_string_literal: true

class VehicleMailer < ApplicationMailer
  default from: Rails.application.secrets[:mailer_default_from].to_s

  def on_sale(vehicle)
    @vehicle = vehicle

    mail(
      to: vehicle.user.email,
      subject: I18n.t(:"mailer.vehicle.on_sale.subject", model: vehicle.model.name)
    )
  end
end
