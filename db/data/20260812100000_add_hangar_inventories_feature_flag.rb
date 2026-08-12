# frozen_string_literal: true

class AddHangarInventoriesFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    Flipper.add("hangar_inventories")

    FeatureSetting.find_or_create_by(feature_name: "hangar_inventories") do |feature_setting|
      feature_setting.self_service = true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
