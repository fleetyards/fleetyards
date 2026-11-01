# frozen_string_literal: true

module Supporters
  # Tells a donor, the day after, that their supporter perks have ended -- the
  # plaque styles above all, which are a perk whether or not a fleet is
  # involved.
  #
  # A monthly Ko-fi subscriber is given the reconciler's grace first: a renewal
  # that lands a day or two late would otherwise be greeted with "your perks
  # ended" just before it arrives.
  class CoverageEndedNoticeJob < ::ApplicationJob
    sidekiq_options queue: "default", retry: 3

    def perform
      ended_on = Date.current - 1
      subscription_ended_on = ended_on - ::Subscriptions::Sync::GRACE_DAYS

      candidates(subscription_ended_on, ended_on).group_by(&:user).each do |user, contributions|
        last_day = contributions.any?(&:kofi_subscription?) ? subscription_ended_on : ended_on
        next unless contributions.any? { |contribution| contribution.active_until == last_day }
        next unless due?(user, last_day)

        notify(user, contributions, last_day)
      end
    end

    # Rows whose cover ran out on either day; `active_until` decides, the dates
    # only narrow the read.
    private def candidates(earliest, latest)
      SupporterContribution
        .where.not(user_id: nil)
        .where(
          "(recurring = ? AND started_at BETWEEN ? AND ?) OR (recurring = ? AND ended_at BETWEEN ? AND ?)",
          false, earliest - 1.month - 3.days, latest - 27.days,
          true, earliest.beginning_of_month, latest
        )
        .includes(:user)
        .select { |contribution| contribution.active_until.in?([earliest, latest]) }
    end

    private def due?(user, last_day)
      return false if user.maintainer? || user.supporter?

      user.supporter_contributions.none? { |contribution| contribution.started_at > last_day } &&
        !::Notification.where(user:, notification_type: "supporter_coverage_ended")
          .where("created_at > ?", 1.week.ago)
          .exists?
    end

    private def notify(user, contributions, last_day)
      I18n.with_locale(user.notification_locale) do
        ::Notification.notify!(
          user:,
          type: :supporter_coverage_ended,
          title: I18n.t("notifications.supporter_coverage_ended.title"),
          body: I18n.t("notifications.supporter_coverage_ended.body", date: I18n.l(last_day, format: :long)),
          link: Rails.application.routes.url_helpers.frontend_support_path,
          record: contributions.max_by(&:started_at)
        )
      end
    end
  end
end
