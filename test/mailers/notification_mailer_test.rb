# frozen_string_literal: true

require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "the body is rendered as markdown" do
    notification = Notification.new(
      user: create(:user),
      notification_type: :fleet_fid_claim_opened,
      title: "Maru claims the fleet ID MARU",
      body: "**On the date:**\n\n- one\n- two",
      link: "/fleets/maru/settings/rsi/"
    )

    mail = NotificationMailer.notification(notification)
    html = mail.html_part&.body&.decoded || mail.body.encoded

    assert_equal "Maru claims the fleet ID MARU", mail.subject
    assert_includes html, "<strong>On the date:</strong>"
    assert_includes html, "<li>one</li>"
    assert_includes html, "/fleets/maru/settings/rsi/"
    assert_includes html, I18n.t("mailer.notification.action")
  end

  # Its announcement was taken down while the mail was still queued.
  test "drops the mail of a notification deleted before it went out" do
    notification = create(:notification, title: "New announcement in MARU")
    job = NotificationMailer.delivery_job.new("NotificationMailer", "notification", "deliver_now", args: [notification])
    queued = job.serialize
    notification.delete

    assert_no_emails do
      ActiveJob::Base.execute(queued)
    end
  end
end
