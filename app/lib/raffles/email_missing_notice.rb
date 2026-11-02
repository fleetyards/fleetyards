# frozen_string_literal: true

module Raffles
  # Tells the entrants of an open raffle whose account has only a placeholder
  # address that the draw will pass them over unless they add a real one.
  class EmailMissingNotice
    def initialize(raffle)
      @raffle = raffle
    end

    def call
      return 0 unless @raffle.open?

      entrants.each { |user| notify(user) }.size
    end

    # A replayed run must not DM the same entrant twice.
    private def entrants
      told = Notification.where(notification_type: :raffle_email_missing, record: @raffle).select(:user_id)
      @raffle.entries.where.not(user_id: told).includes(:user).filter_map(&:user).select(&:placeholder_email?)
    end

    private def notify(user)
      I18n.with_locale(user.notification_locale) do
        Notification.notify!(
          user:,
          type: :raffle_email_missing,
          title: I18n.t("notifications.raffle_email_missing.title", raffle: @raffle.localized_title),
          body: I18n.t(
            "notifications.raffle_email_missing.body",
            deadline: I18n.l(@raffle.ends_at, format: :long)
          ),
          link: Rails.application.routes.url_helpers.frontend_raffle_path(@raffle),
          icon: "fa-duotone fa-envelope",
          record: @raffle
        )
      end
    end
  end
end
