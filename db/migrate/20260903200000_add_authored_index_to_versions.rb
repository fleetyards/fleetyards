# frozen_string_literal: true

class AddAuthoredIndexToVersions < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # `versions` carries an index on (item_type, item_id) and nothing else, so a
    # feed of "what did the admins change lately" -- ordered by time, filtered to
    # rows an admin action wrote -- is a sequential scan over 612k rows.
    #
    # Partial, because `author_id` is only ever set by an admin action: 532 of
    # those 612k rows qualify. The index is a rounding error in size and the feed
    # reads straight off it.
    add_index :versions,
      :created_at,
      order: {created_at: :desc},
      where: "author_id IS NOT NULL",
      name: "index_versions_on_created_at_where_authored",
      algorithm: :concurrently
  end
end
