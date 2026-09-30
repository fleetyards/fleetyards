# frozen_string_literal: true

require "test_helper"

# A notification's text is stored, so it has to be written in the language of
# whoever reads it -- not of the request or job that happened to create it.
class NotificationReaderLocaleTest < ActiveSupport::TestCase
  setup do
    UserNotificationsChannel.stubs(:broadcast_to)
    FleetMembershipMailer.stubs(:new_invite).returns(stub(deliver_later: true))
    FleetMembershipMailer.stubs(:member_requested).returns(stub(deliver_later: true))
  end

  test "an invite sent from an English request reaches a German reader in German" do
    reader = create(:user, locale: "de")
    membership = create(:fleet_membership, :invited, user: reader)

    I18n.with_locale(:en) { membership.notify_invited_user }

    notification = reader.notifications.find_by!(notification_type: :fleet_invite)
    assert_equal I18n.t("notifications.fleet_invite.title", fleet: membership.fleet.name, locale: :de), notification.title
  end

  test "one request fans out to each admin in their own language" do
    fleet = create(:fleet)
    german = create(:user, locale: "de")
    french = create(:user, locale: "fr")
    create(:fleet_membership, :accepted, :as_admin, fleet:, user: german)
    create(:fleet_membership, :accepted, :as_admin, fleet:, user: french)
    requester = create(:user)
    membership = create(:fleet_membership, :requested, fleet:, user: requester)

    I18n.with_locale(:en) { membership.notify_fleet_admins }

    [[german, :de], [french, :fr]].each do |admin, locale|
      notification = admin.notifications.find_by!(notification_type: :fleet_member_requested)
      expected = I18n.t("notifications.fleet_member_requested.title", username: requester.username, fleet: fleet.name, locale:)
      assert_equal expected, notification.title, "for the #{locale} admin"
    end
  end

  test "a notification a job creates is in the reader's language, not the job's default" do
    reader = create(:user, locale: "fr")
    model = create(:model)
    create(:vehicle, user: reader, model:, wanted: true, sale_notify: true, notify: true)
    reader.update!(sale_notify: true)
    VehicleMailer.stubs(:on_sale).returns(stub(deliver_later: true))
    ::Discord::ShipOnSale.any_instance.stubs(:run)

    I18n.with_locale(:en) { ::Notifications::ModelOnSaleJob.new.perform(model.id) }

    notification = reader.notifications.find_by!(notification_type: :model_on_sale)
    assert_equal I18n.t("notifications.model_on_sale.title", model: model.name, locale: :fr), notification.title
  end

  # A mail job renders in the locale it was enqueued in.
  test "the mail is enqueued in the reader's language" do
    reader = create(:user, locale: "it")
    reader.notification_preferences.find_by!(notification_type: :fleet_invite).update!(mail: true)
    enqueued_in = nil
    Notification.stubs(:mailer_for).returns(->(_notification) { enqueued_in = I18n.locale })

    I18n.with_locale(:en) { Notification.notify!(user: reader, type: :fleet_invite, title: "Invited") }

    assert_equal :it, enqueued_in
  end

  test "a reader without a usable locale gets English" do
    [nil, "", "xx"].each do |stored|
      reader = create(:user)
      reader.update_column(:locale, stored)

      assert_equal :en, reader.notification_locale, "for #{stored.inspect}"
    end
  end
end
