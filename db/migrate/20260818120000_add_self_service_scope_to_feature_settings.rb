# frozen_string_literal: true

class AddSelfServiceScopeToFeatureSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :feature_settings, :self_service_scope, :string, null: false, default: "user"
  end
end
