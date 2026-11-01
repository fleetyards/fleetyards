# frozen_string_literal: true

module Supporters
  # Tells a one-off donor a few days ahead that their perks are about to end,
  # and asks them to switch to a monthly donation.
  #
  # Only when nothing else carries them on: a standing pledge, a monthly Ko-fi
  # subscription that will renew by itself, or a later donation all mean the
  # day is not actually the end. Ko-fi payments recorded before the importer
  # kept the subscription flag cannot be told apart from one-offs, so those
  # subscribers may get one reminder they did not need.
  class CoverageEndingReminderJob < ::ApplicationJob
    sidekiq_options queue: "default", retry: 3

    DAYS_AHEAD = 3

    def perform
      ending_on = Date.current + DAYS_AHEAD

      ending_contributions(ending_on).group_by(&:user).each do |user, contributions|
        next unless due?(user, ending_on)

        remind(user, contributions, ending_on)
      end
    end

    # A month from the 28th to the 31st all clamp to the same last day, so the
    # window is widened and `active_until` decides.
    private def ending_contributions(ending_on)
      SupporterContribution
        .where(recurring: false, kofi_subscription: false)
        .where.not(user_id: nil)
        .where(started_at: (ending_on - 1.month - 3.days)..(ending_on - 27.days))
        .includes(:user, :fleet)
        .select { |contribution| contribution.active_until == ending_on }
    end

    private def due?(user, ending_on)
      return false if user.maintainer?
      return false unless user.supporter_until == ending_on
      return false if user.active_supporter_contributions.any?(&:kofi_subscription?)

      !::Notification.where(user:, notification_type: "supporter_coverage_ending")
        .where("created_at > ?", 1.week.ago)
        .exists?
    end

    private def remind(user, contributions, ending_on)
      fleet = contributions.filter_map(&:fleet).first

      I18n.with_locale(user.notification_locale) do
        date = I18n.l(ending_on, format: :long)
        body =
          if fleet
            I18n.t("notifications.supporter_coverage_ending.body_with_fleet", date:, fleet: fleet.name)
          else
            I18n.t("notifications.supporter_coverage_ending.body", date:)
          end

        ::Notification.notify!(
          user:,
          type: :supporter_coverage_ending,
          title: I18n.t("notifications.supporter_coverage_ending.title", date:),
          body:,
          link: Rails.application.routes.url_helpers.frontend_support_path,
          record: contributions.max_by(&:started_at)
        )
      end
    end
  end
end
