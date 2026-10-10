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

    test "tells nobody twice when it runs again" do
      FleetAnnouncementPostedJob.new.perform(@announcement.id)
      ::Push::DeliverNotificationJob.jobs.clear

      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_equal 2, notified.count
      assert_empty ::Push::DeliverNotificationJob.jobs
    end

    test "mails, pushes and messages only the members who asked for it" do
      @member.notification_preferences
        .find_or_create_by!(notification_type: "fleet_announcement_posted")
        .update!(mail: true, push: true, discord: true)
      ::Push::DeliverNotificationJob.jobs.clear
      ::Discord::DeliverNotificationJob.jobs.clear
      NotificationMailer.expects(:notification).with { |notification| notification.user == @member }
        .returns(stub(deliver_later: true))

      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      notification = notified.find_by!(user: @member)
      assert_equal [[notification.id, false]], ::Push::DeliverNotificationJob.jobs.map { |job| job["args"] }
      assert_equal [[notification.id]], ::Discord::DeliverNotificationJob.jobs.map { |job| job["args"] }
    end

    test "files it as read for a member who turned the app channel off" do
      @other.notification_preferences
        .find_or_create_by!(notification_type: "fleet_announcement_posted")
        .update!(app: false)

      FleetAnnouncementPostedJob.new.perform(@announcement.id)

      assert_predicate notified.find_by!(user: @other), :read?
      refute_predicate notified.find_by!(user: @member), :read?
    end

    test "is enqueued when an announcement is posted, not when it is edited" do
      FleetAnnouncementPostedJob.jobs.clear

      announcement = create(:fleet_announcement, fleet: @fleet, author: @author)
      announcement.update!(body: "Reworded")

      assert_equal [[announcement.id]], FleetAnnouncementPostedJob.jobs.map { |job| job["args"] }
    end
  end
end
