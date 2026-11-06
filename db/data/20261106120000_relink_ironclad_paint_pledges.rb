# frozen_string_literal: true

# An "Ironclad - Aquamarine" pledge now stands for the Ironclad Assault's paint
# as well. The Assault already carries those paints, so no import creates one and
# nothing else would relink the pledges synced before the mapping.
class RelinkIroncladPaintPledges < ActiveRecord::Migration[8.1]
  # Relinking rewrites every paint pledge's links, and a hangar sync writing the
  # same rows would wait on all of them until a wrapping transaction committed.
  disable_ddl_transaction!

  def up
    HangarPledgeItems::PaintLinker.new.link_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
