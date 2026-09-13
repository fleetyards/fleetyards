# frozen_string_literal: true

# A friendship between two users, and the request that made it.
#
# **One row per pair, and the pair is unordered.** Two mirrored rows would make
# "who are my friends" a single-column index scan, and would also double every
# write, give one relationship two states that can disagree, and hand the state
# machine a row it did not transition. So: one row, `requester` and `addressee`
# recording who asked -- which the inbox needs in order to label a request --
# and no authority attached to either column once the row is accepted. Either
# side may end it, and every read is over both columns.
#
# Uniqueness is enforced on the unordered pair. Without it, A asking B and B
# asking A produce two rows for one relationship and the second acceptance has
# nothing left to do. `LEAST`/`GREATEST` are immutable over `uuid`, so the
# expression is indexable.
#
# **Cascade, not set-null.** Unlike `inventory_transfers`, which had to stay
# behind after an account went so a fleet kept its history, a friendship with a
# deleted account is not evidence of anything and there are no goods behind it.
# This is the same argument `inventory_transfer_rules` made.
class CreateFriendships < ActiveRecord::Migration[8.1]
  def change
    create_table :friendships, id: :uuid do |t|
      # Named for the roles rather than for the type: the table already says
      # both ends are users, and same-named columns are what let one concern
      # own the handshake for friendships and fleet alliances alike.
      t.references :requester, type: :uuid, null: false,
        foreign_key: {to_table: :users, on_delete: :cascade}
      t.references :addressee, type: :uuid, null: false,
        foreign_key: {to_table: :users, on_delete: :cascade}

      t.string :aasm_state, null: false, default: "pending"

      t.datetime :accepted_at
      t.datetime :declined_at
      t.datetime :ignored_at

      t.timestamps
    end

    add_check_constraint :friendships, "requester_id <> addressee_id",
      name: "friendships_not_to_self"

    add_index :friendships, "LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)",
      unique: true, name: "index_friendships_on_pair"

    # The inbox, and the cap that keeps a stranger from filling one. Partial,
    # because only pending rows are ever counted this way.
    add_index :friendships, :addressee_id, where: "aasm_state = 'pending'",
      name: "index_friendships_on_pending_addressee"
  end
end
