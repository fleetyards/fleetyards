# frozen_string_literal: true

class AddIndexesForSlowQueries < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # `uniqueness: {case_sensitive: false}` on email and username compares
    # LOWER(column), which no plain index on the column can answer, so both
    # validations scanned the whole table on every user save.
    add_index :users, "LOWER(email)", name: "index_users_on_lower_email", algorithm: :concurrently
    add_index :users, "LOWER(username)", name: "index_users_on_lower_username", algorithm: :concurrently

    # The login lookup reads either normalized column; only username was indexed.
    add_index :users, :normalized_email, algorithm: :concurrently

    # Two accounts out of sixty thousand opt out of tracking, and every stats
    # request read the whole table to find them. Partial, so the index holds
    # only those rows and answers from itself.
    add_index :users, :id, where: "tracking = false",
      name: "index_users_on_id_where_not_tracking", algorithm: :concurrently

    # The hangar sync status endpoint polls for a user's latest import, and
    # nothing indexed the column it filters on.
    add_index :imports, :user_id, algorithm: :concurrently

    # Batched iteration over one import type walks the primary key in order.
    add_index :imports, [:type, :id], algorithm: :concurrently

    add_index :components, :name, algorithm: :concurrently
  end
end
