# frozen_string_literal: true

class AddBlueskyFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.add("oauth-bluesky")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
