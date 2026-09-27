# frozen_string_literal: true

class AddInstalledToAhoyVisits < ActiveRecord::Migration[8.1]
  # Visits recorded before this keep NULL rather than taking the default, so a
  # rollup can leave out the ones that never had a way to report the flag.
  def change
    add_column :ahoy_visits, :installed, :boolean
    change_column_default :ahoy_visits, :installed, from: nil, to: false
  end
end
