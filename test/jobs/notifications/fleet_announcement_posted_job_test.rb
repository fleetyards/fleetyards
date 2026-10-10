# frozen_string_literal: true

require "test_helper"

module Notifications
  class FleetAnnouncementPostedJobTest < ActiveSupport::TestCase
    setup do
      @author = create(:user)
      @member = create(:user, locale: "de")
      @other = create(:user)
      @fleet = create(:fleet, name: "MARU", admins: [@author], members: [@member, @other])
      @announcement = create(:fleet_announcement, fleet: @fleet, author: @author,
        body: "Ops night moves to **Friday** this week.")
      ::Discord::DeliverAnnouncementJob.jobs.clear
    end

    def notified
      Notification.where(notification_type: "fleet_announcement_posted")
    end

    test "tells every member but the author" do
      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_equal [@member.id, @other.id].sort, notified.pluck(:user_id).sort
      notification = notified.find_by!(user: @other)
      assert_equal "New announcement in MARU", notification.title
      assert_includes notification.body, "Ops night moves to Friday"
      assert_equal "/fleets/#{@fleet.slug}/", notification.link
      assert_equal @announcement, notification.record
    end

    test "writes each notification in the reader's own language" do
      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_equal "Neue Ankündigung in MARU", notified.find_by!(user: @member).title
    end

    test "leaves out somebody who has left or only asked to join" do
      @fleet.fleet_memberships.find_by(user: @other).discard!
      applicant = create(:user)
      create(:fleet_membership, :requested, fleet: @fleet, user: applicant)

      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_equal [@member.id], notified.pluck(:user_id)
    end

    test "says nothing about an announcement taken down before the queue reached it" do
      @announcement.destroy!

      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_empty notified
    end

    test "says nothing about an announcement that ran out before the queue reached it" do
      @announcement.update_columns(expires_at: 1.minute.ago)

      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_empty notified
    end

    test "posts to the fleet's Discord when it has somewhere to post" do
      @fleet.create_fleet_notification_setting!(discord_webhook_url: "https://discord.com/api/webhooks/1/token")

      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_equal 1, ::Discord::DeliverAnnouncementJob.jobs.size
      content = ::Discord::DeliverAnnouncementJob.jobs.first["args"][3]
      assert_includes content, "Announcement from MARU"
      assert_includes content, "Ops night moves to **Friday**"
    end

    test "posts nothing to a fleet without Discord" do
      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_empty ::Discord::DeliverAnnouncementJob.jobs
    end

    test "keeps going past a member who cannot be notified" do
      Notification.stubs(:notify!).raises("boom").then.returns(nil)

      assert_nothing_raised { FleetAnnouncementPostedJob.new.perform(@announcement.id) }
    end
  end
end
