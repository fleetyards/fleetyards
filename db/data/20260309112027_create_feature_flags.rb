# frozen_string_literal: true

class CreateFeatureFlags < ActiveRecord::Migration[7.2]
  def up
    %w[
      tools_travel_times
      tools_cargo_grids
      hardpoints-v2
      oauth-discord
      oauth-github
      oauth-twitch
      oauth-google
      oauth-applications
    ].each do |name|
      Flipper.add(name)
    end

    %w[tools_cargo_grids].each do |name|
      FeatureSetting.find_or_create_by(feature_name: name) do |fs|
        fs.self_service = true
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
