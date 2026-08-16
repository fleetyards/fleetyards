# frozen_string_literal: true

require "test_helper"

class AdminNotificationTest < ActiveSupport::TestCase
  setup do
    AdminNotificationsChannel.stubs(:broadcast_to)
  end

  test "fans out to every admin holding the type's privilege" do
    with_access = create(:admin_user, resource_access: [:models])
    without_access = create(:admin_user, resource_access: [:users])

    AdminNotification.notify!(type: :paints_import, title: "Paints Import Results")

    assert_equal 1, AdminNotification.where(admin_user: with_access).count
    assert_equal 0, AdminNotification.where(admin_user: without_access).count
  end

  test "reaches super admins regardless of their resource access" do
    super_admin = create(:admin_user, :super_admin, resource_access: [])

    AdminNotification.notify!(type: :paints_import, title: "Paints Import Results")

    assert_equal 1, AdminNotification.where(admin_user: super_admin).count
  end

  test "defaults expires_at from the type's retention" do
    create(:admin_user, resource_access: [:models])

    notification = AdminNotification.notify!(type: :paints_import, title: "Paints Import Results").first

    assert_in_delta 30.days.from_now, notification.expires_at, 5.seconds
  end

  test "picks up the type's icon when none is given" do
    create(:admin_user, resource_access: [:models])

    notification = AdminNotification.notify!(type: :paints_import, title: "Paints Import Results").first

    assert_equal "fa-duotone fa-palette", notification.icon
  end

  test "folds a repeated report into the unread row instead of stacking up" do
    create(:admin_user, resource_access: [:models])

    3.times do
      AdminNotification.notify!(
        type: :paints_import,
        title: "Paints Import Results",
        body: "No new Paints found",
        dedupe_key: "same"
      )
    end

    assert_equal 1, AdminNotification.count
    assert_equal 3, AdminNotification.first.occurrences
  end

  test "starts a new row once the deduped one has been read" do
    create(:admin_user, resource_access: [:models])

    AdminNotification.notify!(type: :paints_import, title: "Paints Import Results", dedupe_key: "same").first.mark_as_read!
    AdminNotification.notify!(type: :paints_import, title: "Paints Import Results", dedupe_key: "same")

    assert_equal 2, AdminNotification.count
  end

  test "keeps reports with differing bodies apart" do
    create(:admin_user, resource_access: [:models])

    AdminNotification.notify!(type: :paints_import, title: "Paints Import Results", dedupe_key: "first")
    AdminNotification.notify!(type: :paints_import, title: "Paints Import Results", dedupe_key: "second")

    assert_equal 2, AdminNotification.count
  end

  test "does not raise when the broadcast fails" do
    create(:admin_user, resource_access: [:models])
    AdminNotificationsChannel.stubs(:broadcast_to).raises(StandardError, "cable down")

    assert_nothing_raised do
      AdminNotification.notify!(type: :paints_import, title: "Paints Import Results")
    end

    assert_equal 1, AdminNotification.count
  end

  test "active and expired split on expires_at" do
    admin_user = create(:admin_user, resource_access: [:models])
    active = create(:admin_notification, admin_user:)
    expired = create(:admin_notification, :expired, admin_user:)

    assert_includes AdminNotification.active, active
    assert_includes AdminNotification.expired, expired
  end
end
