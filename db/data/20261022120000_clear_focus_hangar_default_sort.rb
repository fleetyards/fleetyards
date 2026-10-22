# frozen_string_literal: true

# The hangar no longer sorts by a ship's focus, and a default sort it does not
# offer would fail every later save of the user it belongs to.
class ClearFocusHangarDefaultSort < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE users SET hangar_default_sort = NULL
      WHERE hangar_default_sort IN ('modelFocus asc', 'modelFocus desc')
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
