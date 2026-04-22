# frozen_string_literal: true

class AddCitizenIdFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.add("oauth-citizen_id")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
