# frozen_string_literal: true

# Accounts created while this type was app-only were given a row with mail off.
# Mail was not a channel of it then, so that row is the old default rather than
# anybody's choice, and it would keep them from the mail the type sends now.
class MailFleetRsiVerificationLost < ActiveRecord::Migration[8.1]
  def up
    NotificationPreference
      .where(notification_type: "fleet_rsi_verification_lost", mail: false)
      .update_all(mail: true, updated_at: Time.current)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
