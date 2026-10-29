# frozen_string_literal: true

class AddTranslationsToRaffles < ActiveRecord::Migration[8.1]
  def change
    add_column :raffles, :translations, :jsonb, default: {}, null: false
  end
end
