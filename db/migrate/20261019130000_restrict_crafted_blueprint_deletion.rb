# frozen_string_literal: true

# A crafted lot is told apart by its recipe. Nullified, two lots crafted from
# a deleted recipe at different grades would read as one, and a withdrawal
# could no longer say which it came out of. Nothing deletes a recipe -- a
# retired one is kept -- so refusing costs nothing.
class RestrictCraftedBlueprintDeletion < ActiveRecord::Migration[8.1]
  TABLES = %i[inventory_items fleet_inventory_items].freeze

  def up
    TABLES.each do |table|
      remove_foreign_key table, column: :crafted_blueprint_id
      add_foreign_key table, :blueprints, column: :crafted_blueprint_id, on_delete: :restrict
    end
  end

  def down
    TABLES.each do |table|
      remove_foreign_key table, column: :crafted_blueprint_id
      add_foreign_key table, :blueprints, column: :crafted_blueprint_id, on_delete: :nullify
    end
  end
end
