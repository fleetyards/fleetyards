# frozen_string_literal: true

# The review notification used to link a `q[...]` query the admin list never
# read. Now that the list sends every URL key to the API as a filter, that
# link is an unknown filter and the page fails to load.
class PointOauthReviewNotificationsAtThePendingFilter < ActiveRecord::Migration[8.1]
  def up
    AdminNotification
      .where(notification_type: "oauth_application_review", link: "/oauth-applications?q[aasm_state_eq]=pending")
      .update_all(link: "/oauth-applications/?aasmStateEq=pending")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
