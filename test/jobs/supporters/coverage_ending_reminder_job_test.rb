# frozen_string_literal: true

require "test_helper"

module Supporters
  class CoverageEndingReminderJobTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
    end

    private def reminders(user = @user)
      ::Notification.where(user:, notification_type: "supporter_coverage_ending")
    end

    # Paid 16 October, covered until 15 November, reminded on the 12th.
    private def donate(**attrs)
      create(:supporter_contribution, user: @user, started_at: Date.new(2026, 10, 16), **attrs)
    end

    test "a one-off donor is reminded three days before their support ends" do
      donate

      travel_to Date.new(2026, 11, 12) do
        CoverageEndingReminderJob.new.perform
      end

      reminder = reminders.sole
      assert_includes reminder.title, I18n.l(Date.new(2026, 11, 15), format: :long)
      assert_equal "/support/", reminder.link
    end

    test "nobody is reminded on any other day" do
      donate

      [Date.new(2026, 11, 11), Date.new(2026, 11, 13)].each do |day|
        travel_to(day) { CoverageEndingReminderJob.new.perform }
      end

      assert_empty reminders
    end

    test "the reminder names the fleet that loses its features" do
      membership = create(:fleet_membership, :accepted, user: @user)
      donate(fleet: membership.fleet)

      travel_to(Date.new(2026, 11, 12)) { CoverageEndingReminderJob.new.perform }

      assert_includes reminders.sole.body, membership.fleet.name
    end

    test "a monthly Ko-fi subscriber is not reminded" do
      donate(kofi_subscription: true)

      travel_to(Date.new(2026, 11, 12)) { CoverageEndingReminderJob.new.perform }

      assert_empty reminders
    end

    test "a later donation that carries support on means no reminder" do
      donate
      create(:supporter_contribution, user: @user, started_at: Date.new(2026, 11, 1))

      travel_to(Date.new(2026, 11, 12)) { CoverageEndingReminderJob.new.perform }

      assert_empty reminders
    end

    test "a standing pledge means no reminder" do
      donate
      create(:supporter_contribution, :recurring, user: @user, started_at: 1.year.ago.to_date, ended_at: nil)

      travel_to(Date.new(2026, 11, 12)) { CoverageEndingReminderJob.new.perform }

      assert_empty reminders
    end

    test "a second run on the same day sends nothing more" do
      donate

      travel_to Date.new(2026, 11, 12) do
        CoverageEndingReminderJob.new.perform
        CoverageEndingReminderJob.new.perform
      end

      assert_equal 1, reminders.count
    end

    test "a donation paid on the 31st is reminded once at the clamped month end" do
      create(:supporter_contribution, user: @user, started_at: Date.new(2026, 1, 31))

      (Date.new(2026, 2, 20)..Date.new(2026, 2, 28)).each do |day|
        travel_to(day) { CoverageEndingReminderJob.new.perform }
      end

      assert_equal 1, reminders.count
    end

    test "the reminder is mailed by default" do
      donate

      NotificationMailer.expects(:notification)
        .with { |notification| notification.notification_type == "supporter_coverage_ending" }
        .returns(stub(deliver_later: true))

      travel_to(Date.new(2026, 11, 12)) { CoverageEndingReminderJob.new.perform }
    end
  end
end
