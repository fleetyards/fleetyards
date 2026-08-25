# frozen_string_literal: true

require "test_helper"

module Notifications
  class AdminJobTest < ActiveJob::TestCase
    include ActionMailer::TestHelper

    setup do
      AdminNotificationsChannel.stubs(:broadcast_to)
    end

    test "#perform mails the digest to every super admin individually" do
      first = create(:admin_user, :super_admin)
      second = create(:admin_user, :super_admin)
      create(:admin_user, resource_access: [:models])

      recipients = []
      AdminMailer.stubs(:weekly).with do |admin_user, _report|
        recipients << admin_user
        true
      end.returns(stub(deliver_now: true))

      ::Notifications::AdminJob.new.perform

      assert_equal [first, second].map(&:id).sort, recipients.map(&:id).sort
    end

    test "#perform passes a report covering every section" do
      create(:admin_user, :super_admin)

      captured = nil
      AdminMailer.stubs(:weekly).with do |_admin_user, report|
        captured = report
        true
      end.returns(stub(deliver_now: true))

      ::Notifications::AdminJob.new.perform

      assert_equal %i[growth engagement supporters ops content], captured[:sections].map(&:key)
      assert_includes captured[:sections].first.metrics.map(&:key), :wishes
    end

    # The report carries Struct values, so an ActiveJob hand-off raises
    # SerializationError and no digest ever reaches an inbox.
    test "#perform delivers the digest without an ActiveJob hand-off" do
      create(:admin_user, :super_admin)
      # The CSS inliner runs as a delivery interceptor and would fetch the
      # stylesheet over HTTP, which no test can reach.
      Premailer::Rails::Hook.stubs(:delivering_email)

      assert_emails 1 do
        ::Notifications::AdminJob.new.perform
      end
    end

    test "#perform records the report as an admin notification" do
      admin_user = create(:admin_user, resource_access: [:stats])
      AdminMailer.stubs(:weekly).returns(stub(deliver_now: true))

      ::Notifications::AdminJob.new.perform

      notification = AdminNotification.find_by(admin_user:, notification_type: "weekly_stats")
      assert_not_nil notification
      assert_includes notification.body, "New Registrations"
    end
  end
end
