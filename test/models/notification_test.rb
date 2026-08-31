# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                :uuid             not null, primary key
#  archived_at       :datetime
#  body              :text
#  expires_at        :datetime         not null
#  icon              :string
#  link              :string
#  notification_type :string           not null
#  read_at           :datetime
#  record_type       :string
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  record_id         :uuid
#  user_id           :uuid             not null
#
# Indexes
#
#  index_notifications_on_expires_at               (expires_at)
#  index_notifications_on_notification_type        (notification_type)
#  index_notifications_on_record                   (record_type,record_id)
#  index_notifications_on_user_id_and_archived_at  (user_id,archived_at)
#  index_notifications_on_user_id_and_created_at   (user_id,created_at DESC)
#  index_notifications_on_user_id_and_read_at      (user_id,read_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    UserNotificationsChannel.stubs(:broadcast_to)
  end

  test "creates an unread notification and broadcasts when app is enabled" do
    notification = Notification.notify!(
      user: @user,
      type: :hangar_create,
      title: "Test"
    )

    assert notification.persisted?
    assert_nil notification.read_at
  end

  test "creates a read notification without broadcast when app is disabled" do
    set_preference(@user, "hangar_create", app: false)

    UserNotificationsChannel.expects(:broadcast_to).never

    notification = Notification.notify!(
      user: @user,
      type: :hangar_create,
      title: "Test"
    )

    assert notification.persisted?
    assert notification.read_at.present?
  end

  test "sends model_on_sale email when mail preference is enabled" do
    vehicle = create(:vehicle, user: @user)
    set_preference(@user, "model_on_sale", app: true, mail: true)

    VehicleMailer.expects(:on_sale).with(vehicle).returns(stub(deliver_later: true))

    Notification.notify!(
      user: @user,
      type: :model_on_sale,
      title: "On sale",
      record: vehicle
    )
  end

  test "does not send model_on_sale email when mail preference is disabled" do
    vehicle = create(:vehicle, user: @user)
    set_preference(@user, "model_on_sale", app: true, mail: false)

    VehicleMailer.expects(:on_sale).never

    Notification.notify!(
      user: @user,
      type: :model_on_sale,
      title: "On sale",
      record: vehicle
    )
  end

  test "sends new_model email when mail preference is enabled" do
    model = create(:model)
    set_preference(@user, "new_model", mail: true)

    ModelMailer.expects(:notify_new).with(@user.email, model).returns(stub(deliver_later: true))

    Notification.notify!(
      user: @user,
      type: :new_model,
      title: "New ship",
      record: model
    )
  end

  test "sends fleet_invite email when mail preference is enabled" do
    fleet = create(:fleet)
    membership = create(:fleet_membership, :invited, fleet: fleet, user: @user)

    FleetMembershipMailer.expects(:new_invite).with(@user.email, @user.username, fleet).returns(stub(deliver_later: true))

    Notification.notify!(
      user: @user,
      type: :fleet_invite,
      title: "Invited",
      record: membership
    )
  end

  test "does not send fleet_invite email when mail preference is disabled" do
    fleet = create(:fleet)
    membership = create(:fleet_membership, :invited, fleet: fleet, user: @user)
    set_preference(@user, "fleet_invite", mail: false)

    FleetMembershipMailer.expects(:new_invite).never

    Notification.notify!(
      user: @user,
      type: :fleet_invite,
      title: "Invited",
      record: membership
    )
  end

  test "sends fleet_member_requested email when mail preference is enabled" do
    requesting_user = create(:user)
    fleet = create(:fleet, admins: [@user])
    membership = create(:fleet_membership, fleet: fleet, user: requesting_user, aasm_state: :requested)

    FleetMembershipMailer.expects(:member_requested).with(@user.email, requesting_user.username, fleet).returns(stub(deliver_later: true))

    Notification.notify!(
      user: @user,
      type: :fleet_member_requested,
      title: "Request",
      record: membership
    )
  end

  test "sends fleet_member_accepted email when mail preference is enabled" do
    accepted_user = create(:user)
    fleet = create(:fleet, admins: [@user])
    membership = create(:fleet_membership, fleet: fleet, user: accepted_user, aasm_state: :accepted)

    FleetMembershipMailer.expects(:member_accepted).with(@user.email, accepted_user.username, fleet).returns(stub(deliver_later: true))

    Notification.notify!(
      user: @user,
      type: :fleet_member_accepted,
      title: "Accepted",
      record: membership
    )
  end

  test "sends fleet_request_accepted email when mail preference is enabled" do
    fleet = create(:fleet)
    membership = create(:fleet_membership, fleet: fleet, user: @user, aasm_state: :accepted)

    FleetMembershipMailer.expects(:fleet_accepted).with(@user.email, @user.username, fleet).returns(stub(deliver_later: true))

    Notification.notify!(
      user: @user,
      type: :fleet_request_accepted,
      title: "Accepted",
      record: membership
    )
  end

  %i[hangar_create hangar_destroy wishlist_create wishlist_destroy hangar_sync_finished hangar_sync_failed].each do |type|
    test "#{type} only supports app channel" do
      assert_equal %i[app], Notification.channels_for(type)
    end
  end

  %i[new_model fleet_invite fleet_member_requested fleet_member_accepted fleet_request_accepted].each do |type|
    test "#{type} supports app and mail channels" do
      assert_equal %i[app mail], Notification.channels_for(type)
    end
  end

  # The only type that can also be delivered as a Discord DM so far.
  test "model_on_sale supports app, mail and discord channels" do
    assert_equal %i[app mail discord], Notification.channels_for(:model_on_sale)
  end

  test "stores the polymorphic record" do
    vehicle = create(:vehicle, user: @user)
    set_preference(@user, "model_on_sale", app: true)

    VehicleMailer.stubs(:on_sale).returns(stub(deliver_later: true))

    notification = Notification.notify!(
      user: @user,
      type: :model_on_sale,
      title: "Test",
      record: vehicle
    )

    assert_equal vehicle, notification.record
    assert_equal "Vehicle", notification.record_type
  end

  test "sets 7-day retention for hangar types" do
    notification = Notification.notify!(user: @user, type: :hangar_create, title: "Test")
    assert_in_delta (Time.current + 7.days).to_f, notification.expires_at.to_f, 1.0
  end

  test "sets 30-day retention for sale types" do
    set_preference(@user, "model_on_sale", app: true)
    VehicleMailer.stubs(:on_sale).returns(stub(deliver_later: true))

    notification = Notification.notify!(user: @user, type: :model_on_sale, title: "Test", record: create(:vehicle, user: @user))
    assert_in_delta (Time.current + 30.days).to_f, notification.expires_at.to_f, 1.0
  end

  test "sets 90-day retention for sync types" do
    notification = Notification.notify!(user: @user, type: :hangar_sync_finished, title: "Test")
    assert_in_delta (Time.current + 90.days).to_f, notification.expires_at.to_f, 1.0
  end

  test "archiving takes a notification out of the inbox and back" do
    notification = create(:notification, user: @user)

    notification.archive!

    assert notification.archived?
    assert_includes Notification.archived, notification
    assert_not_includes Notification.inbox, notification

    notification.unarchive!

    assert_not notification.archived?
    assert_includes Notification.inbox, notification
  end

  test ".archive_expired! files expired inbox notifications into the archive" do
    expired = create(:notification, :expired, user: @user)
    current = create(:notification, user: @user)

    Notification.archive_expired!

    assert expired.reload.archived?
    assert_not current.reload.archived?
  end

  test ".archive_expired! leaves an already archived notification alone" do
    archived = create(:notification, :expired, :archived, user: @user)
    archived_at = archived.archived_at

    Notification.archive_expired!

    assert_equal archived_at.to_i, archived.reload.archived_at.to_i
  end

  test "purgeable only covers what has served its term in the archive" do
    fresh = create(:notification, :archived, user: @user)
    old = create(:notification, user: @user, archived_at: (Notification::ARCHIVE_RETENTION + 1.day).ago)

    assert_includes Notification.purgeable, old
    assert_not_includes Notification.purgeable, fresh
  end

  test "#deletes_at counts from the archive, not from expiry" do
    notification = create(:notification, user: @user)

    assert_nil notification.deletes_at

    notification.archive!

    assert_in_delta (Time.current + Notification::ARCHIVE_RETENTION).to_f, notification.deletes_at.to_f, 1.0
  end

  test "the tab scopes move a notification on its expiry date, not on the job" do
    expired = create(:notification, :expired, user: @user)
    current = create(:notification, user: @user)

    assert_includes Notification.filed, expired
    assert_not_includes Notification.pending, expired
    assert_includes Notification.pending, current
  end

  test "marking a notification unread clears read_at" do
    notification = create(:notification, :read, user: @user)

    notification.mark_as_unread!

    assert_not notification.read?
    assert_nil notification.read_at
  end

  test "the unread ransacker sorts unread notifications first" do
    read = create(:notification, :read, user: @user, title: "read")
    unread = travel_to(1.hour.ago) { create(:notification, user: @user, title: "unread") }

    result = Notification.ransack(sorts: ["unread desc", "created_at desc"]).result

    assert_equal [unread, read], result.to_a
  end

  test "the search alias matches title and body" do
    titled = create(:notification, user: @user, title: "Aurora MR added")
    bodied = create(:notification, user: @user, title: "On sale", body: "The **Aurora MR** is on sale")
    create(:notification, user: @user, title: "Hangar sync finished")

    result = Notification.ransack(search_cont: "aurora").result

    assert_equal [titled, bodied].map(&:id).sort, result.map(&:id).sort
  end

  test ".preference_defaults_for returns opt-in defaults for model_on_sale" do
    assert_equal({app: false, mail: false, push: false, discord: false},
      Notification.preference_defaults_for(:model_on_sale))
  end

  test ".preference_defaults_for returns mail-enabled defaults for fleet types" do
    assert_equal({app: true, mail: true, push: false, discord: false},
      Notification.preference_defaults_for(:fleet_invite))
  end

  test ".preference_defaults_for returns standard defaults for app-only types" do
    assert_equal({app: true, mail: false, push: false, discord: false},
      Notification.preference_defaults_for(:hangar_create))
  end

  private

  def set_preference(user, type, **attrs)
    user.notification_preferences.find_by!(notification_type: type).update!(**attrs)
  end
end
