# frozen_string_literal: true

# The flag itself comes from config/feature_flags.yml — feature_flags:sync
# creates it on deploy. Only the self-service setting still lives in the
# database, so that users can enable hangar inventories from Settings >
# Features without an admin flipping it per account.
class AddHangarInventoriesFeatureFlag < ActiveRecord::Migration[8.1]
  def up
    FeatureSetting.find_or_create_by(feature_name: "hangar_inventories") do |feature_setting|
      feature_setting.self_service = true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
