# frozen_string_literal: true

# A ship the game files describe that Fleetyards has no model for.
#
# The RSI ship matrix is the only thing that creates a `Model`, and the sc_data
# loader only iterates rows that already exist. So a ship that is in the game and
# not on the matrix -- a referral bonus, an in-game-only variant, a new hull --
# is invisible, and nothing says so. This is the record that says so.
#
# A row per identifier rather than per build: the same file reappears every
# patch, and a decision about it should only be made once.
class CreateScDataUnlistedModels < ActiveRecord::Migration[8.1]
  def change
    create_table :sc_data_unlisted_models, id: :uuid do |t|
      t.string :identifier, null: false
      t.string :name

      # Which build first showed it, so a later run can tell a genuinely new
      # ship from one that has been sitting undecided for months.
      t.string :first_seen_version, null: false
      t.string :first_seen_environment, null: false
      t.string :last_seen_version, null: false
      t.string :last_seen_environment, null: false

      # What the export lets us work out on its own: the manufacturer from the
      # identifier prefix, and the ship it appears to be a variant of.
      t.string :manufacturer_code
      t.references :base_model, type: :uuid, null: true,
        foreign_key: {to_table: :models, on_delete: :nullify}

      # How it compares to that base ship -- identical, a different stock
      # loadout, or a different machine. Descriptive, not a verdict: the export
      # never says whether a player can own something, which is the only
      # question the catalogue cares about.
      t.string :comparison

      # Null while undecided. A decided row stops being reported.
      t.string :decision
      t.references :model, type: :uuid, null: true,
        foreign_key: {on_delete: :nullify}
      t.datetime :decided_at

      t.timestamps
    end

    add_index :sc_data_unlisted_models, :identifier, unique: true
    # The report asks for undecided rows on every load.
    add_index :sc_data_unlisted_models, :decision
  end
end
