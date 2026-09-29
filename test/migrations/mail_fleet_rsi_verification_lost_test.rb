# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20260929140000_mail_fleet_rsi_verification_lost.rb")

class MailFleetRsiVerificationLostTest < ActiveSupport::TestCase
  test "a row made while the type was app-only gets mail" do
    user = create(:user)
    preference = NotificationPreference.find_or_create_by!(user:, notification_type: :fleet_rsi_verification_lost)
    preference.update!(mail: false)
    other = NotificationPreference.find_or_create_by!(user:, notification_type: :fleet_invite)
    other.update!(mail: false)

    MailFleetRsiVerificationLost.new.up

    assert preference.reload.mail?
    assert_not other.reload.mail?
  end
end
