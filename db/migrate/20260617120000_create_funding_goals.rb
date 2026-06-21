# frozen_string_literal: true

class CreateFundingGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :funding_goals, id: :uuid do |t|
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "EUR"
      t.date :effective_from, null: false

      t.timestamps
    end

    add_index :funding_goals, :effective_from
  end
end
