# frozen_string_literal: true

# The ship views import skips a ship whose listing is unchanged, and the paints'
# stencil sheets were published before paints had a field for them. Clearing the
# digest makes the next run read those listings again; maps already attached are
# matched by their MD5 and not fetched.
class ReimportShipViewsForPaintStencils < ActiveRecord::Migration[8.1]
  def up
    Model.with_textured_holo.where.not(ship_views_digest: nil).update_all(ship_views_digest: nil)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
