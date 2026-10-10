# frozen_string_literal: true

require "test_helper"

module Notifications
  class BroadcastWithdrawnJobTest < ActiveSupport::TestCase
    test "tells only the readers a live message can still reach" do
      here = create(:user, last_active_at: Time.current)
      away = create(:user, last_active_at: 3.days.ago)
      UserNotificationsChannel.expects(:broadcast_to).with(here, {withdrawnIds: ["a"]}).once

      BroadcastWithdrawnJob.new.perform({here.id => ["a"], away.id => ["b"]})
    end

    test "is enqueued once an announcement with notifications is taken down" do
      member = create(:user)
      fleet = create(:fleet, members: [member])
      announcement = create(:fleet_announcement, fleet:)
      notification = create(:notification, user: member, notification_type: "fleet_announcement_posted",
        record: announcement)
      BroadcastWithdrawnJob.jobs.clear

      announcement.destroy!

      assert_equal [[{member.id => [notification.id]}]], BroadcastWithdrawnJob.jobs.map { |job| job["args"] }
    end
  end
end
