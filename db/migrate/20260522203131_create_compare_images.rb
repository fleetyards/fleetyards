# frozen_string_literal: true

class CreateCompareImages < ActiveRecord::Migration[8.1]
  def change
    create_table :compare_images, id: :uuid do |t|
      t.string :slug_set, null: false

      t.timestamps
    end

    add_index :compare_images, :slug_set, unique: true
  end
end
