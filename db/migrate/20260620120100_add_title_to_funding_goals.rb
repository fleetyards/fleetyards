# frozen_string_literal: true

class AddTitleToFundingGoals < ActiveRecord::Migration[8.1]
  def change
    add_column :funding_goals, :title, :string
    add_column :funding_goals, :description, :text
    add_column :funding_goals, :ended_at, :date

    add_index :funding_goals, :ended_at
  end
end
