# frozen_string_literal: true

class AddPostedPartsToAnnouncementDeliveries < ActiveRecord::Migration[8.1]
  def change
    # What of a multi-part delivery actually landed.
    #
    # A thread is posted one call at a time and none of the three platforms can
    # unsend one, so a failure on post 2 of 3 leaves post 1 standing. Without a
    # record of that, an admin retry starts again from the first part and
    # publishes it a second time -- which is the duplicate the whole delivery
    # design exists to avoid.
    #
    # jsonb because what identifies a part differs per platform: X hands back
    # an id, Bluesky a uri and a cid (a reply needs both), Discord nothing at
    # all beyond the fact that the message went.
    add_column :announcement_deliveries, :posted_parts, :jsonb, default: [], null: false
  end
end
