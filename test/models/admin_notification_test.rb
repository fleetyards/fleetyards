# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: admin_notifications
#
#  id                :uuid             not null, primary key
#  body              :text
#  dedupe_key        :string
#  expires_at        :datetime         not null
#  icon              :string
#  last_occurred_at  :datetime         not null
#  link              :string
#  notification_type :string           not null
#  occurrences       :integer          default(1), not null
#  read_at           :datetime
#  record_type       :string
#  severity          :string           default("info"), not null
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  admin_user_id     :uuid             not null
#  record_id         :uuid
#
# Indexes
#
#  index_admin_notifications_on_admin_user_id_and_created_at  (admin_user_id,created_at DESC)
#  index_admin_notifications_on_admin_user_id_and_read_at     (admin_user_id,read_at)
#  index_admin_notifications_on_dedupe                        (admin_user_id,notification_type,dedupe_key) UNIQUE WHERE ((read_at IS NULL) AND (dedupe_key IS NOT NULL))
#  index_admin_notifications_on_expires_at                    (expires_at)
#  index_admin_notifications_on_notification_type             (notification_type)
#  index_admin_notifications_on_record                        (record_type,record_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id) ON DELETE => cascade
#
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
