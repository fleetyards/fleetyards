# frozen_string_literal: true

class FleetMailerPreview < ActionMailer::Preview
  def fleet_notification
    FleetMailer.fleet_notification(
      Notification.new(
        user: User.first || User.new(username: "commander", email: "commander@example.com"),
        notification_type: :fleet_fid_claim_opened,
        title: "Ghost Squadron claims the fleet ID GHOST",
        body: "Ghost Squadron proved it runs the RSI organisation GHOST, so it can claim the matching fleet ID.",
        link: "/fleets/ghost/settings/rsi/"
      )
    )
  end
end
