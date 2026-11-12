# frozen_string_literal: true

class AddLandingServicesToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :landing_services, :jsonb
    add_column :model_builds, :landing_services, :jsonb
  end
end
