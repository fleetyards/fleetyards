# frozen_string_literal: true

class AnnouncementMailerPreview < ActionMailer::Preview
  def published
    AnnouncementMailer.published(sample_notification)
  end

  # Unsaved stand-ins when the database is empty, which is the state
  # MjmlRenderingTest and a fresh checkout both run in.
  private def sample_notification
    announcement = Announcement.new(
      title: "Fleet contracts are here",
      body: "Fleets can now post **jobs** to their members.\n\nOpen the fleet's board to see what is waiting.",
      link: "/fleets/"
    )

    Notification.new(
      user: User.first || User.new(username: "commander", email: "foo@bar.de"),
      notification_type: :announcement,
      title: announcement.title,
      body: announcement.body,
      link: announcement.link,
      icon: Announcement::DEFAULT_ICON,
      record: announcement
    )
  end
end
