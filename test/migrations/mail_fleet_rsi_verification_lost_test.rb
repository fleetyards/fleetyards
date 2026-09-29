# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260929140000_mail_fleet_rsi_verification_lost.rb")

class MailFleetRsiVerificationLostTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  # The state signup left behind while the type was app-only.
  def signup_default
    NotificationPreference.find_by!(user: @user, notification_type: :fleet_rsi_verification_lost).tap do |preference|
      preference.update_columns(mail: false, created_at: preference.created_at, updated_at: preference.created_at) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  test "an untouched signup default gets mail" do
    preference = signup_default

    MailFleetRsiVerificationLost.new.up

    assert preference.reload.mail?
  end

  test "a row the reader changed keeps its opt-out" do
    preference = signup_default
    travel 1.minute
    preference.update!(mail: false, app: true, updated_at: Time.current)

    MailFleetRsiVerificationLost.new.up

    assert_not preference.reload.mail?
  end

  test "a row the reader created on its own keeps its opt-out" do
    NotificationPreference.where(user: @user, notification_type: :fleet_rsi_verification_lost).delete_all
    travel 1.minute
    preference = NotificationPreference.create!(user: @user, notification_type: :fleet_rsi_verification_lost, mail: false)

    MailFleetRsiVerificationLost.new.up

    assert_not preference.reload.mail?
  end

  test "other types are left alone" do
    signup_default
    other = NotificationPreference.find_by!(user: @user, notification_type: :fleet_invite)
    other.update_columns(mail: false, updated_at: other.created_at) # rubocop:disable Rails/SkipsModelValidations

    MailFleetRsiVerificationLost.new.up

    assert_not other.reload.mail?
  end
end
