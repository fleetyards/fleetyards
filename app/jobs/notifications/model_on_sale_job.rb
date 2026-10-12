# frozen_string_literal: true

require "discord/ship_on_sale"

module Notifications
  class ModelOnSaleJob < Notifications::BaseJob
    def perform(model_id)
      model = Model.find(model_id)

      ::Discord::ShipOnSale.new(model:).run if model.pledge_price.present?

      user_ids = User.confirmed
        .where(id: NotificationPreference.model_on_sale.on_any_channel.select(:user_id))
        .select(:id)

      Vehicle.where(model_id:, sale_notify: true, wanted: true, loaner: false, user_id: user_ids, notify: true).includes(:user).find_each do |vehicle|
        I18n.with_locale(vehicle.user.notification_locale) do
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
end
