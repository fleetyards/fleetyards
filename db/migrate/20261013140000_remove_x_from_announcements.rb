# frozen_string_literal: true

class RemoveXFromAnnouncements < ActiveRecord::Migration[8.1]
  # A delivery to a channel the enum no longer names cannot be loaded, so the
  # history of X sends goes with the channel.
  def up
    execute "DELETE FROM announcement_deliveries WHERE channel = 'x'"
    remove_column :announcements, :post_x
  end

  def down
    add_column :announcements, :post_x, :boolean, default: false, null: false
  end
end
