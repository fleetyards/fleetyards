# frozen_string_literal: true

class AddActiveWeekStreakToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :active_week_streak, :integer, default: 0, null: false
    add_column :users, :last_active_week, :date
  end
end
