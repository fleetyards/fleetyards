# frozen_string_literal: true

require "test_helper"

module Supporters
  class CoverageEndedNoticeJobTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
    end

    private def notices
      ::Notification.where(user: @user, notification_type: "supporter_coverage_ended")
    end

    # Paid 16 October, covered until 15 November.
    private def donate(**attrs)
      create(:supporter_contribution, user: @user, started_at: Date.new(2026, 10, 16), **attrs)
    end

    private def run_on(day)
      travel_to(day) { CoverageEndedNoticeJob.new.perform }
    end

    test "a donor without any fleet is told the day after their perks end" do
      donate

      run_on Date.new(2026, 11, 16)

      notice = notices.sole
      assert_includes notice.body, I18n.l(Date.new(2026, 11, 15), format: :long)
      assert_equal "/support/", notice.link
    end

    test "nobody is told before the perks end, or again later" do
      donate

      [Date.new(2026, 11, 15), Date.new(2026, 11, 16), Date.new(2026, 11, 17)].each { |day| run_on day }

      assert_equal 1, notices.count
    end

    test "a later donation means the perks did not end" do
      donate
      create(:supporter_contribution, user: @user, started_at: Date.new(2026, 11, 14))

      run_on Date.new(2026, 11, 16)

      assert_empty notices
    end

    test "a Ko-fi subscriber is given the grace days before being told" do
      donate(kofi_subscription: true)

      run_on Date.new(2026, 11, 16)
      assert_empty notices

      run_on Date.new(2026, 11, 19)
      assert_equal 1, notices.count
    end

    test "a Ko-fi subscriber whose renewal arrives late is never told" do
      donate(kofi_subscription: true)
      run_on Date.new(2026, 11, 16)

      create(:supporter_contribution, user: @user, started_at: Date.new(2026, 11, 17), kofi_subscription: true)
      run_on Date.new(2026, 11, 19)

      assert_empty notices
    end

    test "an ended standing pledge is announced after its last month" do
      create(:supporter_contribution, :recurring, user: @user,
        started_at: Date.new(2026, 1, 1), ended_at: Date.new(2026, 10, 5))

      run_on Date.new(2026, 11, 1)

      assert_equal 1, notices.count
    end

    test "a maintainer is never told" do
      @user.update!(maintainer: true)
      donate

      run_on Date.new(2026, 11, 16)

      assert_empty notices
    end
  end
end
