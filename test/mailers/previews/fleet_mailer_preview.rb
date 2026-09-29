# frozen_string_literal: true

class FleetMailerPreview < ActionMailer::Preview
  def fleet_notification
    FleetMailer.fleet_notification(
      Notification.new(
        user: User.first || User.new(username: "commander", email: "commander@example.com"),
        notification_type: :fleet_fid_claim_opened,
        title: "Ghost Squadron claims the fleet ID GHOST",
        body: I18n.t("notifications.fleet_fid_claim_opened.body",
          claimant: "Ghost Squadron", fid: "GHOST", fleet: "Ghost Hunters", date: I18n.l(14.days.from_now.to_date, format: :long)),
        link: "/fleets/ghost/settings/rsi/"
      )
    )
  end
end
