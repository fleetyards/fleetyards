# frozen_string_literal: true

# Accounts created while this type was app-only were given a row with mail off,
# and that default would keep them from the mail the type sends now. A row a
# reader wrote through the preference API is their choice and stays as it is.
#
# Signup inserts every type's row in one batch, so an untouched default is one
# that shares its creation time with the user's other rows and was never
# written again. A row the API created or changed has a moment of its own.
class MailFleetRsiVerificationLost < ActiveRecord::Migration[8.1]
  def up
    NotificationPreference
      .where(notification_type: "fleet_rsi_verification_lost", mail: false)
      .where("notification_preferences.updated_at = notification_preferences.created_at")
      .where(<<~SQL.squish)
        EXISTS (
          SELECT 1 FROM notification_preferences batch
          WHERE batch.user_id = notification_preferences.user_id
            AND batch.id <> notification_preferences.id
            AND batch.created_at = notification_preferences.created_at
        )
      SQL
      .update_all(mail: true, updated_at: Time.current)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
