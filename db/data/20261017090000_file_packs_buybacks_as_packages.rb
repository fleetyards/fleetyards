# frozen_string_literal: true

# RSI titles a buy-back of several ships "Packs - ...", which the list sync
# stored as `other` until it read that prefix as a package.
class FilePacksBuybacksAsPackages < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE buyback_pledges SET kind = 'package'
      WHERE kind = 'other' AND name LIKE 'Packs - %'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
