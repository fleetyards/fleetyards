# frozen_string_literal: true

require "discord/ship_on_sale"

module Notifications
  class ModelOnSaleJob < Notifications::BaseJob
    def perform(model_id)
      model = Model.find(model_id)

      ::Discord::ShipOnSale.new(model:).run if model.pledge_price.present?

      user_ids = User.confirmed.where(sale_notify: true).pluck(&:id)

      Vehicle.where(model_id:, sale_notify: true, wanted: true, loaner: false, user_id: user_ids, notify: true).find_each do |vehicle|
        OnSaleHangarChannel.broadcast_to(vehicle.user, vehicle.to_json)

        Notification.notify!(
          user: vehicle.user,
          type: :model_on_sale,
          title: I18n.t("notifications.model_on_sale.title", model: model.name),
          body: I18n.t("notifications.model_on_sale.body", model: model.name),
          link: Rails.application.routes.url_helpers.frontend_model_path(model.slug),
          record: vehicle
        )
      end
    end
  end
end
