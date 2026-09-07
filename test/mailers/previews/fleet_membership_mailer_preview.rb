# frozen_string_literal: true

class FleetMembershipMailerPreview < ActionMailer::Preview
  def new_invite
    FleetMembershipMailer.new_invite("foo@bar.de", username, fleet)
  end

  def member_requested
    FleetMembershipMailer.member_requested(["foo@bar.de", "bar@foo.de"], username, fleet)
  end

  def fleet_accepted
    FleetMembershipMailer.fleet_accepted("foo@bar.de", username, fleet)
  end

  def member_accepted
    FleetMembershipMailer.member_accepted(["foo@bar.de", "bar@foo.de"], username, fleet)
  end

  # These read `User.first.username` and `Fleet.first` directly, so on a database
  # with neither - every fresh worktree - all four previews died on
  # NoMethodError for nil. Real records are still preferred; the fallbacks only
  # supply the two attributes the mails actually show.
  private def username
    User.first&.username || "Commander"
  end

  private def fleet
    Fleet.first || Fleet.new(name: "Ghost Squadron", slug: "ghost-squadron")
  end
end
