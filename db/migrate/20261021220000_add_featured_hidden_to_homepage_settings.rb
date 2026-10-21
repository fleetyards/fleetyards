# frozen_string_literal: true

class AddFeaturedHiddenToHomepageSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :homepage_settings, :featured_hidden, :boolean, default: false, null: false
  end
end
