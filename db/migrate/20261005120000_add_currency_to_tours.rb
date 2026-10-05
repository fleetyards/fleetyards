# frozen_string_literal: true

class AddCurrencyToTours < ActiveRecord::Migration[8.1]
  def change
    add_column :tours, :currency, :string, default: "auec", null: false
  end
end
