# frozen_string_literal: true

class RemoveAppleFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.remove("oauth-apple")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
