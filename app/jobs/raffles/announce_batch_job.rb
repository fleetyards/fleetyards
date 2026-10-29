# frozen_string_literal: true

module Raffles
  # Writes one batch of users the notification that a raffle opened or has a
  # day left, in bulk like announcements.
  class AnnounceBatchJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    RECIPIENT_INDEX = :index_notifications_on_raffle_announcement_recipient

    def perform(raffle_id, type, user_ids)
      raffle = Raffle.find_by(id: raffle_id)
      return if raffle.blank? || user_ids.blank?

      link = Rails.application.routes.url_helpers.frontend_raffle_path(raffle)
      locales = User.where(id: user_ids).pluck(:id, :locale).to_h
      deadline = raffle.ends_at

      Notifications::BulkDelivery.notify(
        type: type.to_sym,
        user_ids:,
        unique_by: RECIPIENT_INDEX,
        mailer: ->(notification) { NotificationMailer.notification(notification).deliver_later },
        label: "Raffle"
      ) do |user_id|
        locale = User.new(locale: locales[user_id]).notification_locale
        I18n.with_locale(locale) do
          {
            title: I18n.t("notifications.#{type}.title", raffle: raffle.localized_title),
            body: I18n.t("notifications.#{type}.body", raffle: raffle.localized_title, deadline: I18n.l(deadline, format: :long)),
            link:,
            icon: "fa-duotone fa-ticket",
            record_type: "Raffle",
            record_id: raffle.id
          }
        end
      end
    end
  end
end
