# frozen_string_literal: true

class AddEngagementToAnnouncementDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :announcement_deliveries, :engagement, :jsonb
    add_column :announcement_deliveries, :engagement_fetched_at, :datetime
  end
end
