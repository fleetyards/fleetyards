class AddDeletedAtToProgressTrackerItems < ActiveRecord::Migration[6.0]
  def change
    add_column :progress_tracker_items, :deleted_at, :datetime
  end
end
