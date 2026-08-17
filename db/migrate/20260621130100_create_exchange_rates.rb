# frozen_string_literal: true

class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates, id: :uuid do |t|
      t.string :from_currency, null: false
      t.string :to_currency, null: false
      t.decimal :rate, precision: 16, scale: 8, null: false
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    add_index :exchange_rates, [:from_currency, :to_currency], unique: true
  end
end
