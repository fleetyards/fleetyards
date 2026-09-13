# frozen_string_literal: true

# Reporting a transfer as spam, and the queue an admin reviews it in.
#
# Reporting is what makes the rest of the controls enforceable: a denial
# protects one recipient, and a spammer working through a fresh target list is
# unaffected by it.
#
# The report carries no copy of what was sent. It does not need one -- a
# transfer's contents are its ledger entries, and those are never deleted, so a
# declined transfer stays fully readable as evidence and there is nothing for
# the sender to erase. That is a property the append-only ledger gives for free.
class CreateInventoryTransferReports < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_transfer_reports, id: :uuid do |t|
      t.references :inventory_transfer, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.references :reporter, type: :uuid, null: true,
        foreign_key: {to_table: :users, on_delete: :nullify}

      # Which fleet the reporter was acting for, when they reported on behalf of
      # one rather than for themselves.
      t.references :fleet, type: :uuid, null: true,
        foreign_key: {to_table: :fleets, on_delete: :cascade}

      t.integer :reason, null: false, default: 0
      t.text :note

      t.string :aasm_state, null: false, default: "open"

      t.references :reviewed_by, type: :uuid, null: true,
        foreign_key: {to_table: :admin_users, on_delete: :nullify}
      t.datetime :reviewed_at
      t.text :resolution_note

      t.timestamps
    end

    # One report per reporter per transfer. Filing again is not more signal.
    add_index :inventory_transfer_reports, [:inventory_transfer_id, :reporter_id],
      unique: true, where: "reporter_id IS NOT NULL",
      name: "index_transfer_reports_on_transfer_and_reporter"

    # What the admin queue lists.
    add_index :inventory_transfer_reports, :created_at, where: "aasm_state = 'open'",
      name: "index_transfer_reports_on_open_created_at"
  end
end
