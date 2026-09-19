# frozen_string_literal: true

# A recipe somebody holds.
#
# Deliberately only the pair. A blueprint in 4.x is an item, so a count is the
# obvious next column -- but how many times one can be used is an announced
# feature the game has not shipped, and a column that starts out meaning "1"
# and later has to mean "uses remaining" is worse than no column. Nothing reads
# a row as a quantity, so adding one stays additive.
#
# Pointed at the blueprint rather than at its build: a build is per environment
# and gets replaced on every load, and what somebody holds does not stop being
# held because a patch landed.
class CreateUserBlueprints < ActiveRecord::Migration[8.1]
  def change
    create_table :user_blueprints, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.references :blueprint, type: :uuid, null: false, foreign_key: {on_delete: :cascade}

      t.timestamps
    end

    # The marker itself, and the index the "do I hold this" lookup reads.
    add_index :user_blueprints, [:user_id, :blueprint_id],
      unique: true, name: "index_user_blueprints_on_user_and_blueprint"
  end
end
