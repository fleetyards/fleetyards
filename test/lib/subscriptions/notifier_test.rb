# frozen_string_literal: true

require "test_helper"

module Subscriptions
  class NotifierTest < ActiveSupport::TestCase
    setup do
      @admin = create(:user)
      @member = create(:user)
      @fleet = create(:fleet, admins: [@admin], members: [@member])
      @subscription = create(:fleet_subscription, fleet: @fleet)
    end

    private def notifications_for(user, type)
      Notification.where(user:, notification_type: type)
    end

    test "opening notifies the fleet's admins" do
      Notifier.started(@subscription)

      assert_equal 1, notifications_for(@admin, :fleet_subscription_started).count
      assert_includes notifications_for(@admin, :fleet_subscription_started).first.title, @fleet.name
    end

    # A member cannot change what the fleet is entitled to, so telling all of
    # them is noise.
    test "a plain member is not notified" do
      Notifier.started(@subscription)

      assert_empty notifications_for(@member, :fleet_subscription_started)
    end

    test "nobody outside the fleet is notified" do
      stranger = create(:user)

      Notifier.started(@subscription)

      assert_empty notifications_for(stranger, :fleet_subscription_started)
    end

    # "Your fleet lost access" without a reason generates a support ticket
    # rather than answering one.
    test "closing says what lapsed and why" do
      seeded = create(:fleet_subscription, :seeded, fleet: create(:fleet, admins: [@admin]))

      Notifier.ended(seeded)

      title = notifications_for(@admin, :fleet_subscription_ended).first.title

      assert_includes title, I18n.t("notifications.fleet_subscription_ended.reasons.contribution")
    end

    test "a comp being ended says an administrator did it" do
      Notifier.ended(@subscription)

      title = notifications_for(@admin, :fleet_subscription_ended).first.title

      assert_includes title, I18n.t("notifications.fleet_subscription_ended.reasons.manual")
    end

    # `notify!` files it read rather than not filing it, which is how this
    # codebase honours a switched-off preference -- the record stays findable in
    # the archive and simply does not announce itself.
    test "an admin who switched the type off gets it already read" do
      NotificationPreference.find_or_initialize_by(
        user: @admin, notification_type: :fleet_subscription_started
      ).update!(app: false)

      Notifier.started(@subscription)

      notification = notifications_for(@admin, :fleet_subscription_started).sole

      assert notification.read_at.present?, "a switched-off type must not arrive unread"
    end

    test "an admin who left it on gets it unread" do
      Notifier.started(@subscription)

      assert_nil notifications_for(@admin, :fleet_subscription_started).sole.read_at
    end

    test "a fleet with no admins raises nothing" do
      lonely = create(:fleet_subscription)

      assert_nothing_raised { Notifier.started(lonely) }
    end

    test "both types are declared with retention and preference defaults" do
      %i[fleet_subscription_started fleet_subscription_ended].each do |type|
        config = Notification::TYPES.fetch(type)

        assert config[:retention].present?, "#{type} has no retention"
        assert_equal true, Notification.preference_defaults_for(type)[:app],
          "#{type} must be on by default, or a fleet learns from a 403"
      end
    end

    I18n.available_locales.each do |locale|
      test "both titles are translated in #{locale}" do
        %w[fleet_subscription_started fleet_subscription_ended].each do |type|
          assert I18n.t(:"notifications.#{type}.title", locale:, default: nil, fallback: false),
            "#{type} has no #{locale} title"
        end

        %w[contribution manual].each do |reason|
          assert I18n.t(:"notifications.fleet_subscription_ended.reasons.#{reason}",
            locale:, default: nil, fallback: false),
            "reason #{reason} has no #{locale} translation"
        end
      end
    end
  end
end
