# frozen_string_literal: true

# Append-only history of every write to a Flipper flag.
#
# `flipper_gates` cannot say how long a flag has been on. A boolean disable
# deletes the gate row rather than updating it, and `FeatureFlags::Synchronizer`
# removes a pruned flag's gates wholesale -- so `flipper_gates.created_at`, the
# only activation signal there was, really means "last switched on, assuming
# nobody has touched it since".
#
# See docs/exec-plans/4972-feature-flag-activation-tracking.md.
class CreateFeatureFlagChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :feature_flag_changes, id: :uuid do |t|
      # Deliberately a string and not a reference: the row has to outlive the
      # flag. Sync prunes a flag the deploy after it leaves
      # config/feature_flags.yml, and the history of a removed flag is the
      # history most worth keeping.
      t.string :feature_name, null: false

      # enable / disable / add / remove / clear. The read operations Flipper
      # publishes on the same event are never recorded.
      t.string :operation, null: false

      # boolean / actor / group / percentage_of_actors / percentage_of_time, and
      # the gate's value -- "User;<uuid>", a group name, a percentage. Both are
      # null for add, remove and clear, which name no gate.
      t.string :gate_name
      t.string :thing

      # `feature.state` read straight after the write. Storing the resulting
      # state rather than only the operation is what makes "fully on since" a
      # query instead of a replay -- and a replay could not see writes from
      # before this table existed anyway.
      t.string :state_after, null: false

      # Which surface was responsible: admin / self_service / sync / console,
      # plus backfill for the rows seeded from flipper_gates.
      t.string :source, null: false

      # Who acted, when a request was responsible. Both null for a console call
      # and for the deploy's own sync. Nullified rather than cascaded: the flag
      # change happened whether or not the account still exists.
      t.references :admin_user, type: :uuid, foreign_key: {on_delete: :nullify}
      t.references :user, type: :uuid, foreign_key: {on_delete: :nullify}

      # No updated_at. Rows are written once and never edited.
      t.datetime :created_at, null: false
    end

    # Every read is "what happened to this flag", newest first.
    add_index :feature_flag_changes, [:feature_name, :created_at], order: {created_at: :desc}
  end
end
