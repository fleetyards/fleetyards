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

  test "folds into the existing row when a concurrent report wins the insert race" do
    admin_user = create(:admin_user, resource_access: [:models])
    existing = create(:admin_notification, admin_user:, dedupe_key: "same")

    # The first lookup misses the way it would for a job that read before the
    # other one inserted; the unique index then forces the retry.
    AdminNotification.stubs(:unread).returns(AdminNotification.none, AdminNotification.where(read_at: nil))

    AdminNotification.notify!(type: :paints_import, title: "Paints Import Results", dedupe_key: "same")

    assert_equal 1, AdminNotification.count
    assert_equal 2, existing.reload.occurrences
  end

  test "lists only the types the admin currently has access to" do
    admin_user = create(:admin_user, resource_access: [:models])

    types = AdminNotification.types_for(admin_user)

    assert_includes types, "paints_import"
    assert_not_includes types, "new_supporter"
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

  test "starts a new row once the deduped one has been archived" do
    create(:admin_user, resource_access: [:models])

    AdminNotification.notify!(type: :paints_import, title: "Paints Import Results", dedupe_key: "same").first.archive!
    AdminNotification.notify!(type: :paints_import, title: "Paints Import Results", dedupe_key: "same")

    assert_equal 2, AdminNotification.count
    assert_equal 1, AdminNotification.inbox.count
  end

  test "archiving leaves the read state alone" do
    admin_user = create(:admin_user, resource_access: [:models])
    notification = create(:admin_notification, admin_user:)

    notification.archive!

    assert_predicate notification, :archived?
    refute_predicate notification, :read?
  end

  test "inbox and archived split on archived_at" do
    admin_user = create(:admin_user, resource_access: [:models])
    inbox = create(:admin_notification, admin_user:)
    archived = create(:admin_notification, :archived, admin_user:)

    assert_includes AdminNotification.inbox, inbox
    assert_includes AdminNotification.archived, archived
  end

  test "marking unread gives up a dedupe key the newer report holds" do
    admin_user = create(:admin_user, resource_access: [:models])
    older = create(:admin_notification, :read, admin_user:, dedupe_key: "same")
    newer = create(:admin_notification, admin_user:, dedupe_key: "same")

    older.mark_as_unread!

    refute_predicate older.reload, :read?
    assert_nil older.dedupe_key
    assert_equal "same", newer.reload.dedupe_key
  end

  test "unarchiving gives up a dedupe key the newer report holds" do
    admin_user = create(:admin_user, resource_access: [:models])
    older = create(:admin_notification, :archived, admin_user:, dedupe_key: "same")
    create(:admin_notification, admin_user:, dedupe_key: "same")

    older.unarchive!

    refute_predicate older.reload, :archived?
    assert_nil older.dedupe_key
  end

  test "active and expired split on expires_at" do
    admin_user = create(:admin_user, resource_access: [:models])
    active = create(:admin_notification, admin_user:)
    expired = create(:admin_notification, :expired, admin_user:)

    assert_includes AdminNotification.active, active
    assert_includes AdminNotification.expired, expired
  end
end
