# frozen_string_literal: true

class CreateTours < ActiveRecord::Migration[8.1]
  def change
    create_table :tours, id: :uuid do |t|
      t.uuid :created_by_id, null: false
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.datetime :starts_at
      t.string :status, null: false, default: "open"
      t.datetime :settled_at
      t.datetime :cancelled_at
      t.string :invite_token, null: false
      t.timestamps
    end

    add_index :tours, :slug, unique: true
    add_index :tours, :invite_token, unique: true
    add_index :tours, [:created_by_id, :status]
    add_foreign_key :tours, :users, column: :created_by_id
  end
end
