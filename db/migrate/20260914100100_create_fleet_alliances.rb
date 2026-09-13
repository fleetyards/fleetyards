# frozen_string_literal: true

# An alliance between two fleets, and the request that made it.
#
# The same shape as `friendships` down to the column names, because it is the
# same handshake: one row per unordered pair, a requester and an addressee that
# carry no authority once accepted, and three answers rather than two. See that
# migration for why the pair is unordered and why the keys cascade.
#
# What differs is who answers. A friendship is answered by the one person it
# names; an alliance is answered by whoever in the fleet holds the privilege for
# it, and commits the fleet's ships, stats and roster to another organisation --
# so it defaults to `fleet:manage` rather than to an officer.
class CreateFleetAlliances < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_alliances, id: :uuid do |t|
      t.references :requester, type: :uuid, null: false,
        foreign_key: {to_table: :fleets, on_delete: :cascade}
      t.references :addressee, type: :uuid, null: false,
        foreign_key: {to_table: :fleets, on_delete: :cascade}

      t.string :aasm_state, null: false, default: "pending"

      t.datetime :accepted_at
      t.datetime :declined_at
      t.datetime :ignored_at

      t.timestamps
    end

    add_check_constraint :fleet_alliances, "requester_id <> addressee_id",
      name: "fleet_alliances_not_to_self"

    add_index :fleet_alliances, "LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)",
      unique: true, name: "index_fleet_alliances_on_pair"

    add_index :fleet_alliances, :addressee_id, where: "aasm_state = 'pending'",
      name: "index_fleet_alliances_on_pending_addressee"
  end
end
