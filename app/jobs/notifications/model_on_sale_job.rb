# frozen_string_literal: true

require 'discord/ship_on_sale'

module Notifications
  class ModelOnSaleJob < Notifications::BaseJob
    def perform(model_id)
      model = Model.find(model_id)

      Discord::ShipOnSale.new(model: model).run

      user_ids = User.confirmed.where(sale_notify: true).pluck(&:id)

      Vehicle.where(model_id: model_id, sale_notify: true, purchased: false, loaner: false, user_id: user_ids, notify: true).find_each do |vehicle|
        OnSaleHangarChannel.broadcast_to(vehicle.user, vehicle.to_json)
        VehicleMailer.on_sale(vehicle).deliver_later
      end
    end
  end
end
