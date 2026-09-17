# frozen_string_literal: true

class AddLastTestedAtToAnnouncements < ActiveRecord::Migration[8.1]
  def change
    # When the dry run last went to the admin channel, so the send button can
    # say whether anybody has looked at this announcement anywhere but in the
    # form that wrote it.
    add_column :announcements, :last_tested_at, :datetime
  end
end
