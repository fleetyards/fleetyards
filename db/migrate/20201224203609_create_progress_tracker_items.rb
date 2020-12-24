class CreateProgressTrackerItems < ActiveRecord::Migration[6.0]
  def change
    create_table :progress_tracker_items, id: :uuid do |t|
      t.string :team
      t.string :title
      t.string :description
      t.date :start_date
      t.date :end_date
      t.string :projects
      t.string :time_allocations

      t.timestamps
    end
  end
end
