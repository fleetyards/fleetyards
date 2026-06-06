# frozen_string_literal: true

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

  %i[model_on_sale new_model fleet_invite fleet_member_requested fleet_member_accepted fleet_request_accepted].each do |type|
    test "#{type} supports app and mail channels" do
      assert_equal %i[app mail], Notification.channels_for(type)
    end
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

  test ".preference_defaults_for returns opt-in defaults for model_on_sale" do
    assert_equal({app: false, mail: false, push: false}, Notification.preference_defaults_for(:model_on_sale))
  end

  test ".preference_defaults_for returns mail-enabled defaults for fleet types" do
    assert_equal({app: true, mail: true, push: false}, Notification.preference_defaults_for(:fleet_invite))
  end

  test ".preference_defaults_for returns standard defaults for app-only types" do
    assert_equal({app: true, mail: false, push: false}, Notification.preference_defaults_for(:hangar_create))
  end

  private

  def set_preference(user, type, **attrs)
    user.notification_preferences.find_by!(notification_type: type).update!(**attrs)
  end
end
