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

    private def nominated_fleet
      fleet = create(:fleet_membership, :accepted, user: @user).fleet

      travel_to Date.new(2026, 10, 16) do
        donate(fleet:, amount_cents: ::Subscriptions.qualifying_amount_cents)
        ::Subscriptions::Sync.call
      end

      fleet
    end

    test "the reminder names the fleet that loses its features, with the reconciler's grace" do
      fleet = nominated_fleet

      travel_to(Date.new(2026, 11, 12)) { CoverageEndingReminderJob.new.perform }

      body = reminders.sole.body
      assert_includes body, fleet.name
      assert_includes body, I18n.l(Date.new(2026, 11, 18), format: :long)
    end

    test "a fleet another donation keeps covered is not named" do
      fleet = nominated_fleet
      other = create(:fleet_membership, :accepted, fleet:).user
      create(:supporter_contribution, user: other, fleet:,
        amount_cents: ::Subscriptions.qualifying_amount_cents, started_at: Date.new(2026, 11, 10))

      travel_to(Date.new(2026, 11, 12)) { CoverageEndingReminderJob.new.perform }

      assert_not_includes reminders.sole.body, fleet.name
    end

    test "a fleet with a dated manual grant that outlasts the donation is not named" do
      fleet = nominated_fleet
      create(:fleet_subscription, fleet:, granted_via: "manual",
        started_at: Date.new(2026, 10, 1), ended_at: Date.new(2027, 1, 31))

      travel_to(Date.new(2026, 11, 12)) { CoverageEndingReminderJob.new.perform }

      assert_not_includes reminders.sole.body, fleet.name
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
