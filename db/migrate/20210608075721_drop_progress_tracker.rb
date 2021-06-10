class DropProgressTracker < ActiveRecord::Migration[6.1]
  def up
    drop_table :progress_tracker_items

    PaperTrail::Version.where(item_type: 'ProgressTrackerItem').destroy_all
  end

  def down
    create_table :progress_tracker_items, id: :uuid do |t|
      t.string :key
      t.string :team
      t.string :title
      t.string :description
      t.date :start_date
      t.date :end_date
      t.string :projects
      t.integer :discipline_counts
      t.string :time_allocations
      t.uuid :model_id

      t.timestamps
    end

    add_index :progress_tracker_items, :key, unique: true
  end
end
