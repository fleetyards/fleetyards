# encoding: utf-8
# frozen_string_literal: true

class VehicleMailerPreview < ActionMailer::Preview
  def on_sale
    vehicle = Vehicle.first
    raise 'Please Create a Vehicle' if vehicle.nil?
    VehicleMailer.on_sale(vehicle)
  end
end
