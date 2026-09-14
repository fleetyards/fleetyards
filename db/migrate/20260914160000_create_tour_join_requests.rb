# frozen_string_literal: true

# A fleet member asking onto one of their fleet's tours.
#
# **Its own table rather than a pending `payout_participants` row.** A
# participant row is a share of the money -- its weight is what the profit is
# divided by -- so a row that exists but must not count would have to be
# excluded from every balance, entry and transfer query, and a single miss
# mis-divides real money. Nothing here touches the ledger until the request is
# approved, and approval is what creates the participant.
#
# The invite link stays the other way in: the token is the credential, and
# someone holding it joins outright. This is for the member who can see the
# tour on their fleet's page and has no link.
class CreateTourJoinRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :tour_join_requests, id: :uuid do |t|
      t.references :tour, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}
      t.references :user, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.string :aasm_state, null: false, default: "pending"

      # Who answered, and when. One pair rather than `approved_at` and
      # `declined_at`: a request is decided once, and the state says which way.
      t.references :decided_by, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :nullify}
      t.datetime :decided_at

      t.timestamps
    end

    # Only pending rows are constrained. A declined request stays as the record
    # of the answer, and must not stop the member asking again later.
    add_index :tour_join_requests, [:tour_id, :user_id],
      unique: true, where: "aasm_state = 'pending'",
      name: "index_tour_join_requests_on_pending_tour_and_user"
  end
end
