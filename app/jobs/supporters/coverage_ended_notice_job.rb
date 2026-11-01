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
      today = Date.current

      candidates(today).each do |user|
        last_day, subscription = last_cover(user)
        next if last_day.nil?
        next unless today == last_day + 1 + (subscription ? ::Subscriptions::Sync::GRACE_DAYS : 0)
        next unless due?(user)

        notify(user, last_day)
      end
    end

    # Donors with something that ran out in the last few days. Narrows the read
    # only; `last_cover` decides.
    private def candidates(today)
      earliest = today - 1 - ::Subscriptions::Sync::GRACE_DAYS

      SupporterContribution
        .where.not(user_id: nil)
        .where(
          "(recurring = ? AND started_at BETWEEN ? AND ?) OR (recurring = ? AND ended_at BETWEEN ? AND ?)",
          false, earliest - 1.month - 3.days, today - 27.days,
          true, earliest.beginning_of_month, today
        )
        .includes(:user)
        .map(&:user)
        .uniq
    end

    # The last day any of the donor's contributions covers, and whether one
    # that covers it is a Ko-fi subscription payment, which earns the grace.
    # Nil while an open-ended pledge covers them.
    private def last_cover(user)
      contributions = user.supporter_contributions.to_a
      days = contributions.map(&:active_until)
      return if days.empty? || days.any?(&:nil?)

      last_day = days.max
      [last_day, contributions.any? { |contribution| contribution.active_until == last_day && contribution.kofi_subscription? }]
    end

    private def due?(user)
      return false if user.maintainer? || user.supporter?

      !::Notification.where(user:, notification_type: "supporter_coverage_ended")
        .where("created_at > ?", 1.week.ago)
        .exists?
    end

    private def notify(user, last_day)
      I18n.with_locale(user.notification_locale) do
        ::Notification.notify!(
          user:,
          type: :supporter_coverage_ended,
          title: I18n.t("notifications.supporter_coverage_ended.title"),
          body: I18n.t("notifications.supporter_coverage_ended.body", date: I18n.l(last_day, format: :long)),
          link: Rails.application.routes.url_helpers.frontend_support_path,
          record: user.supporter_contributions.max_by(&:started_at)
        )
      end
    end
  end
end
