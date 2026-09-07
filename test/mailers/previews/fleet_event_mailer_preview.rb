# frozen_string_literal: true

# FleetEventMailer had no preview, so its template - the one every fleet event
# notification goes out on - could not be looked at, and MjmlRenderingTest, which
# is driven off preview discovery, never checked it either.
#
# One preview per key would be eleven near-identical pages; these three cover
# what actually varies in the template: whether the notification carries a body,
# and the per-key sentence underneath it.
class FleetEventMailerPreview < ActionMailer::Preview
  def published
    FleetEventMailer.published(notification)
  end

  def starting_soon
    FleetEventMailer.starting_soon(notification(body: nil))
  end

  def signup_kicked
    FleetEventMailer.signup_kicked(notification)
  end

  private def notification(body: "Bring a medium fighter and a full load of missiles.")
    Notification.new(
      title: "Operation Nightfall",
      body:,
      user: User.first || User.new(username: "Commander", email: "commander@example.com"),
      record: FleetEvent.new(
        title: "Operation Nightfall",
        slug: "operation-nightfall",
        fleet: Fleet.first || Fleet.new(name: "Ghost Squadron", slug: "ghost-squadron")
      )
    )
  end
end
