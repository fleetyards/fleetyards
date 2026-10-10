# frozen_string_literal: true

# A ship is announced when it is published. These were published while nothing
# announced them, so the moment has passed: hiding and publishing one again
# would announce a months-old ship as new. The Centaurus is left out because it
# went public a day earlier and is still due its announcement.
class MarkPublishedModelsAsNotified < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE models SET notified = TRUE, updated_at = NOW()
      WHERE hidden = FALSE AND notified = FALSE
        AND slug <> 'rsi-constellation-mk-v-centaurus'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
