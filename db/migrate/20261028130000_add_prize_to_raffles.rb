# frozen_string_literal: true

class AddPrizeToRaffles < ActiveRecord::Migration[8.1]
  def change
    add_column :raffles, :prize, :string
  end
end
