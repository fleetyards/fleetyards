# encoding: utf-8
# frozen_string_literal: true

class UserShipMailerPreview < ActionMailer::Preview
  def on_sale
    user_ship = UserShip.first
    raise 'Please Create a UserShip' if user_ship.nil?
    UserShipMailer.on_sale(user_ship)
  end
end
