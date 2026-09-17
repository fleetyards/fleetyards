# frozen_string_literal: true

require "test_helper"

module Announcements
  class NotifyBatchJobTest < ActiveJob::TestCase
    setup do
      @announcement = create(:announcement, :with_link, title: "Contracts", body: "Jobs now.")
    end

    test "#perform writes one notification per reader" do
      users = create_list(:user, 3)

      Announcements::NotifyBatchJob.new.perform(@announcement.id, users.map(&:id))

      notifications = Notification.where(notification_type: "announcement")

      assert_equal 3, notifications.count
      assert_equal users.map(&:id).sort, notifications.pluck(:user_id).sort

      notification = notifications.first
      assert_equal "Contracts", notification.title
      assert_equal "Jobs now.", notification.body
      assert_equal "/fleets/", notification.link
      assert_equal @announcement, notification.record
    end

    test "#perform falls back to the type defaults for a reader with no preference row" do
      user = create(:user)
      user.notification_preferences.where(notification_type: "announcement").delete_all

      Announcements::NotifyBatchJob.new.perform(@announcement.id, [user.id])

      # app defaults to true for this type, so the row arrives unread.
      assert_nil Notification.find_by(user:).read_at
    end

    test "#perform files the notification as read for a reader who turned the app channel off" do
      user = create(:user)
      user.notification_preferences
        .find_or_create_by!(notification_type: "announcement")
        .update!(app: false)

      Announcements::NotifyBatchJob.new.perform(@announcement.id, [user.id])

      assert Notification.find_by(user:).read_at.present?
    end

    test "#perform broadcasts only to readers who were here recently" do
      here = create(:user, last_active_at: 1.minute.ago)
      gone = create(:user, last_active_at: 3.days.ago)

      UserNotificationsChannel.expects(:broadcast_to).with { |user, _payload| user == here }.once

      Announcements::NotifyBatchJob.new.perform(@announcement.id, [here.id, gone.id])
    end

    test "#perform mails only the readers who opted in" do
      opted_in = create(:user, last_active_at: 3.days.ago)
      opted_in.notification_preferences
        .find_or_create_by!(notification_type: "announcement")
        .update!(mail: true)
      opted_out = create(:user, last_active_at: 3.days.ago)

      AnnouncementMailer.expects(:published).with { |notification| notification.user == opted_in }
        .returns(stub(deliver_later: true))
        .once

      Announcements::NotifyBatchJob.new.perform(@announcement.id, [opted_in.id, opted_out.id])
    end

    # A batch job retries, so the second run has to be a no-op: no second row,
    # and -- the part that would actually be noticed -- no second mail.
    test "#perform is idempotent across a retry" do
      user = create(:user, last_active_at: 1.minute.ago)

      UserNotificationsChannel.expects(:broadcast_to).once

      2.times { Announcements::NotifyBatchJob.new.perform(@announcement.id, [user.id]) }

      assert_equal 1, Notification.where(user:, notification_type: "announcement").count
    end

    test "#perform marks the in-app delivery succeeded once every reader has a row" do
      users = create_list(:user, 2)
      @announcement.update!(recipients_count: 2)

      Announcements::NotifyBatchJob.new.perform(@announcement.id, [users.first.id])
      refute @announcement.deliveries.exists?(channel: "in_app", status: "succeeded")

      Announcements::NotifyBatchJob.new.perform(@announcement.id, [users.second.id])
      assert @announcement.deliveries.exists?(channel: "in_app", status: "succeeded")
    end

    test "#perform ignores an empty batch and a missing announcement" do
      assert_nothing_raised do
        Announcements::NotifyBatchJob.new.perform(@announcement.id, [])
        Announcements::NotifyBatchJob.new.perform(SecureRandom.uuid, [create(:user).id])
      end

      assert_equal 0, Notification.where(notification_type: "announcement").count
    end
  end
end
