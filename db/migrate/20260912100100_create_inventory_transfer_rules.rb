# frozen_string_literal: true

# Who may send you a transfer.
#
# A cross-party transfer is the first write path in this app that lets an
# account you have never met put a row in your notification centre, so the
# feature has to bring its own controls -- there is no block, mute or report
# machinery anywhere else to lean on.
#
# Two mechanisms, because the question has two shapes. **Policy** is a stance,
# one column per party: everyone, only people you already share a fleet with, or
# nobody. **Rules** are the exceptions to it, naming one other party to allow or
# deny. Together they express every useful arrangement without a third
# mechanism: `everyone` plus denials is a blocklist, `nobody` plus allowances is
# an allowlist.
#
# The same four-nullable-foreign-key shape as `inventory_transfers`, for the
# same reason: a rule is held by a user or a fleet, and names a user or a fleet.
# Cascade rather than set-null here, unlike the transfers: a rule about an
# account that no longer exists is not evidence of anything and there are no
# goods behind it.
class CreateInventoryTransferRules < ActiveRecord::Migration[8.1]
  # Matching InventoryTransferPolicy on the models. Spelled out rather than read
  # from them, because a migration has to keep running against the schema of its
  # own moment.
  POLICY_EVERYONE = 0

  def change
    create_table :inventory_transfer_rules, id: :uuid do |t|
      # The party holding the rule.
      t.references :user, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :cascade}
      t.references :fleet, type: :uuid, null: true,
        foreign_key: {to_table: :fleets, on_delete: :cascade}

      # The party it names.
      t.references :subject_user, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :cascade}
      t.references :subject_fleet, type: :uuid, null: true,
        foreign_key: {to_table: :fleets, on_delete: :cascade}

      t.integer :effect, null: false, default: 0
      t.text :note

      t.references :created_by, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :nullify}

      t.timestamps
    end

    add_check_constraint :inventory_transfer_rules,
      "(user_id IS NOT NULL)::int + (fleet_id IS NOT NULL)::int = 1",
      name: "inventory_transfer_rules_exactly_one_holder"

    add_check_constraint :inventory_transfer_rules,
      "(subject_user_id IS NOT NULL)::int + (subject_fleet_id IS NOT NULL)::int = 1",
      name: "inventory_transfer_rules_exactly_one_subject"

    # One rule per relationship, flipped rather than stacked. Partial indexes
    # because only one column of each pair is ever set, and a plain composite
    # unique index over four nullable columns enforces nothing -- in Postgres
    # NULLs are distinct, so it would happily admit the same pair twice.
    add_index :inventory_transfer_rules, [:user_id, :subject_user_id],
      unique: true, where: "user_id IS NOT NULL AND subject_user_id IS NOT NULL",
      name: "index_transfer_rules_on_user_and_subject_user"
    add_index :inventory_transfer_rules, [:user_id, :subject_fleet_id],
      unique: true, where: "user_id IS NOT NULL AND subject_fleet_id IS NOT NULL",
      name: "index_transfer_rules_on_user_and_subject_fleet"
    add_index :inventory_transfer_rules, [:fleet_id, :subject_user_id],
      unique: true, where: "fleet_id IS NOT NULL AND subject_user_id IS NOT NULL",
      name: "index_transfer_rules_on_fleet_and_subject_user"
    add_index :inventory_transfer_rules, [:fleet_id, :subject_fleet_id],
      unique: true, where: "fleet_id IS NOT NULL AND subject_fleet_id IS NOT NULL",
      name: "index_transfer_rules_on_fleet_and_subject_fleet"

    # The stance, and the sanction an admin can apply to a sender. The sanction
    # is deliberately narrower than Devise's `locked_at`, which is already
    # available and takes the whole account: spamming transfers should cost an
    # account its transfers and nothing else.
    add_column :users, :inventory_transfer_policy, :integer, null: false, default: POLICY_EVERYONE
    add_column :users, :transfers_blocked_at, :datetime
    add_column :users, :transfers_blocked_reason, :text

    add_column :fleets, :inventory_transfer_policy, :integer, null: false, default: POLICY_EVERYONE
    add_column :fleets, :transfers_blocked_at, :datetime
    add_column :fleets, :transfers_blocked_reason, :text
  end
end
