# frozen_string_literal: true

require "test_helper"

module Notifications
  class NewPatronJobTest < ActiveJob::TestCase
    test "#perform posts to Discord and emails super admins" do
      supporter = create(:supporter_contribution, :patreon, name: "Alice", amount_cents: 500, currency: "EUR")
      Discord::NewSupporter.expects(:new).with(supporter:).returns(stub(run: true))
      AdminMailer.expects(:new_supporter).with(supporter).returns(stub(deliver_later: true))

      ::Notifications::NewPatronJob.new.perform(supporter.id)
    end

    test "#perform still emails when the Discord post fails" do
      supporter = create(:supporter_contribution, :patreon)
      failing = stub
      failing.stubs(:run).raises(StandardError, "discord down")
      Discord::NewSupporter.expects(:new).with(supporter:).returns(failing)
      AdminMailer.expects(:new_supporter).with(supporter).returns(stub(deliver_later: true))
      Appsignal.expects(:report_error)

      assert_nothing_raised do
        ::Notifications::NewPatronJob.new.perform(supporter.id)
      end
    end

    test "#perform does nothing for a manual contribution" do
      supporter = create(:supporter_contribution)
      Discord::NewSupporter.expects(:new).never
      AdminMailer.expects(:new_supporter).never

      ::Notifications::NewPatronJob.new.perform(supporter.id)
    end

    test "#perform does nothing when the record is gone" do
      Discord::NewSupporter.expects(:new).never
      AdminMailer.expects(:new_supporter).never

      assert_nothing_raised do
        ::Notifications::NewPatronJob.new.perform("00000000-0000-0000-0000-000000000000")
      end
    end
  end
end
