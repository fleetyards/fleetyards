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

    # @fleet already holds an open subscription, and the partial unique index
    # allows only one -- so a test needing a second row needs a second fleet.
    private def another_fleet
      create(:fleet, admins: [@admin])
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

      Notifier.ended(seeded, cause: :contribution)

      title = notifications_for(@admin, :fleet_subscription_ended).first.title

      assert_includes title, I18n.t("notifications.fleet_subscription_ended.reasons.contribution")
    end

    test "a comp being ended says an administrator did it" do
      Notifier.ended(@subscription, cause: :manual)

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

    # `open?` and `active_on?` are not the same question, and a rule built on
    # either alone gets one of these wrong.
    test "a grant dated into the future announces nothing yet" do
      future = create(:fleet_subscription, fleet: another_fleet, started_at: Date.current + 7)

      Notifier.announce(future, was_open: false, was_active: false, cause: :manual)

      assert_empty notifications_for(@admin, :fleet_subscription_started)
    end

    test "a grant ending today still announces that it ended" do
      @subscription.update!(started_at: Date.current - 10, ended_at: Date.current)

      Notifier.announce(@subscription, was_open: true, was_active: true, cause: :manual)

      assert_equal 1, notifications_for(@admin, :fleet_subscription_ended).count
    end

    test "moving the start across today announces that it started" do
      @subscription.update!(started_at: Date.current)

      Notifier.announce(@subscription, was_open: true, was_active: false, cause: :manual)

      assert_equal 1, notifications_for(@admin, :fleet_subscription_started).count
    end

    test "an edit that changes neither state announces nothing" do
      Notifier.announce(@subscription, was_open: true, was_active: true, cause: :manual)

      assert_empty Notification.where(user: @admin)
    end

    # An admin closing a contribution-backed grant while the donation is still
    # running must not blame the donation.
    test "the cause is what the caller says, not what granted_via implies" do
      seeded = create(:fleet_subscription, :seeded, fleet: another_fleet, started_at: Date.current - 10)
      seeded.update!(ended_at: Date.current)

      Notifier.announce(seeded, was_open: true, was_active: true, cause: :manual)

      title = notifications_for(@admin, :fleet_subscription_ended).sole.title

      assert_includes title, I18n.t("notifications.fleet_subscription_ended.reasons.manual")
      refute_includes title, I18n.t("notifications.fleet_subscription_ended.reasons.contribution")
    end

    # The title is persisted, so it has to be written in the reader's language
    # rather than in whatever the job happened to run in.
    test "each admin is told in their own locale" do
      german = create(:user, locale: "de")
      create(:fleet_membership, fleet: @fleet, user: german, aasm_state: :accepted,
        fleet_role: @fleet.fleet_roles.ranked.first)

      I18n.with_locale(:en) { Notifier.started(@subscription) }

      assert_includes notifications_for(german, :fleet_subscription_started).sole.title,
        I18n.t("notifications.fleet_subscription_started.title", fleet: @fleet.name, locale: :de)
          .split(" ").last
      assert_equal I18n.t("notifications.fleet_subscription_started.title",
        fleet: @fleet.name, locale: :en),
        notifications_for(@admin, :fleet_subscription_started).sole.title
    end

    test "an unknown stored locale falls back rather than raising" do
      @admin.update_column(:locale, "kl")

      assert_nothing_raised { Notifier.started(@subscription) }
    end
  end
end
