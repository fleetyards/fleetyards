# frozen_string_literal: true

# `manual` is no longer one of the values `source` may hold, so every row still
# carrying it would fail to read back through the enum.
#
# Null rather than `other`, because `manual` never said which platform the
# money arrived on -- only that no importer wrote the row, which is still
# readable from the absence of a patreon_member_id or a kofi_transaction_id.
# Translating it to `other` would assert "a platform, just not a listed one"
# about rows where nobody stated anything, and afterwards the two populations
# could not be told apart.
class RenameManualSupporterContributionSourceToOther < ActiveRecord::Migration[8.1]
  def up
    SupporterContribution.where(source: "manual").update_all(source: nil)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
