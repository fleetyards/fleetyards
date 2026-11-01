# frozen_string_literal: true

class NotificationMailerPreview < ActionMailer::Preview
  def notification
    NotificationMailer.notification(
      Notification.new(
        user: reader,
        notification_type: :fleet_fid_claim_opened,
        title: "Ghost Squadron claims the fleet ID GHOST",
        body: I18n.t("notifications.fleet_fid_claim_opened.body",
          claimant: "Ghost Squadron", fid: "GHOST", fleet: "Ghost Hunters", date: I18n.l(14.days.from_now.to_date, format: :long)),
        link: "/fleets/ghost/settings/rsi/"
      )
    )
  end

  def raffle_started
    raffle_notification(:raffle_started, 14.days.from_now)
  end

  def raffle_last_day
    raffle_notification(:raffle_last_day, 1.day.from_now)
  end

  def supporter_coverage_ending
    date = I18n.l(3.days.from_now.to_date, format: :long)

    NotificationMailer.notification(
      Notification.new(
        user: reader,
        notification_type: :supporter_coverage_ending,
        title: I18n.t("notifications.supporter_coverage_ending.title", date:),
        body: I18n.t("notifications.supporter_coverage_ending.body_with_fleet", date:, fleet: "Ghost Hunters"),
        link: "/support/"
      )
    )
  end

  private def raffle_notification(type, deadline)
    raffle = "Win an Anvil Polaris"

    NotificationMailer.notification(
      Notification.new(
        user: reader,
        notification_type: type,
        title: I18n.t("notifications.#{type}.title", raffle:),
        body: I18n.t("notifications.#{type}.body", raffle:, deadline: I18n.l(deadline, format: :long)),
        link: "/raffles/",
        icon: "fa-duotone fa-gift"
      )
    )
  end

  private def reader
    User.first || User.new(username: "commander", email: "commander@example.com")
  end
end
