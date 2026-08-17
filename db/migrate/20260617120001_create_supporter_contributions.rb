# frozen_string_literal: true

class CreateSupporterContributions < ActiveRecord::Migration[8.1]
  def change
    create_table :supporter_contributions, id: :uuid do |t|
      t.string :name, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "EUR"
      t.boolean :anonymous, null: false, default: false
      t.boolean :recurring, null: false, default: false
      t.date :started_at, null: false
      t.date :ended_at
      t.text :note

      t.timestamps
    end

    add_index :supporter_contributions, :started_at
    add_index :supporter_contributions, [:recurring, :ended_at]
  end
end
