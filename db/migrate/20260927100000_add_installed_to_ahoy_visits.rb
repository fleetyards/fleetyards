# frozen_string_literal: true

class AddInstalledToAhoyVisits < ActiveRecord::Migration[8.1]
  def change
    add_column :ahoy_visits, :installed, :boolean, null: false, default: false
  end
end
