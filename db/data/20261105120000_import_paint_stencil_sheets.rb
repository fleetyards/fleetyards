# frozen_string_literal: true

# The paints' stencil sheets were published before paints had a field for them,
# and the import skips a ship whose listing is unchanged. Clearing the digests
# would also bring back every render detached in the admin, so only the paint
# maps are read again. Migrations run while the old workers are still up, and
# jobs are not retried, so the run waits for the deploy to finish.
class ImportPaintStencilSheets < ActiveRecord::Migration[8.1]
  def up
    ::ScData::ShipViewsImportJob.perform_in(30.minutes, nil, true)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
