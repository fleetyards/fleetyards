# frozen_string_literal: true

# X is no longer a channel. A delivery naming it cannot be loaded once the enum
# drops the value, so its history goes. An announcement that was going nowhere
# but X has no channel left, and a scheduled or failed one would be claimed by
# the sweep and then refused at publish -- stuck in `publishing` for good -- so
# it goes back to draft for somebody to pick a channel.
class RetireXAnnouncementDeliveries < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM announcement_deliveries WHERE channel = 'x'"

    execute <<~SQL.squish
      UPDATE announcements SET status = 'draft'
      WHERE status IN ('scheduled', 'failed')
        AND post_x
        AND NOT (notify_users OR post_discord OR post_bluesky)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
