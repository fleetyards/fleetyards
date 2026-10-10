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

    # Both members are tried: the first failure costs that member only.
    test "keeps going past a member who cannot be notified" do
      Notification.expects(:notify!).twice.raises("boom").then.returns(nil)

      FleetAnnouncementPostedJob.new.perform(@announcement.id)
    end

    # A retry picks up where the last run stopped.
    test "tells nobody twice when it runs again" do
      FleetAnnouncementPostedJob.new.perform(@announcement.id)
      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_equal 2, notified.count
    end
  end
end
