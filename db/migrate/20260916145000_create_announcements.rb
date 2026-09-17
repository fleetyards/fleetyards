# frozen_string_literal: true

class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements, id: :uuid do |t|
      t.string :title, null: false
      t.text :body, null: false

      # The post that goes out to X and Bluesky. Optional: most announcements
      # read fine in 280 characters, and the ones that do not need their own
      # wording rather than a truncated `body` ending mid-sentence.
      t.text :social_body

      t.string :link
      t.string :icon

      t.string :status, default: "draft", null: false
      t.datetime :publish_at
      t.datetime :published_at

      # What the fan-out found when it ran, so the list can say how far an
      # announcement reached without counting rows across a 57k-row insert.
      t.integer :recipients_count

      t.boolean :notify_users, default: true, null: false
      t.boolean :post_discord, default: false, null: false
      t.boolean :post_bluesky, default: false, null: false
      t.boolean :post_x, default: false, null: false

      t.references :admin_user, type: :uuid, foreign_key: true, index: false

      t.timestamps
    end

    add_index :announcements, :status
    add_index :announcements, :published_at, order: {published_at: :desc}
    # The scheduler's only query. Partial because everything else in the table
    # has no publish_at at all, and a scheduled announcement is the rare row.
    add_index :announcements, :publish_at, where: "status = 'scheduled'"

    create_table :announcement_deliveries, id: :uuid do |t|
      t.references :announcement, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.string :channel, null: false
      t.string :status, default: "pending", null: false

      # The post id the platform gave back -- an at:// URI for Bluesky, a tweet
      # id for X -- so a delivered post can be linked to rather than searched
      # for.
      t.string :external_id

      t.text :error
      t.datetime :delivered_at
      t.integer :attempts, default: 0, null: false

      t.timestamps
    end

    # One row per channel per announcement: a retry updates the row it already
    # has rather than stacking a second attempt beside the first.
    add_index :announcement_deliveries, [:announcement_id, :channel], unique: true
  end
end
