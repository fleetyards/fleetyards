# frozen_string_literal: true

# `manual` is no longer one of the values `source` may hold, so every row still
# carrying it would fail to read back through the enum.
#
# `other` is the honest replacement rather than a lossy one: `manual` never said
# which platform the money arrived on, only that no importer wrote the row --
# and that much is still readable from the absence of a patreon_member_id or a
# kofi_transaction_id.
class RenameManualSupporterContributionSourceToOther < ActiveRecord::Migration[8.1]
  def up
    SupporterContribution.where(source: "manual").update_all(source: "other")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
