# frozen_string_literal: true

class CreateHomepageSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :homepage_settings, id: :uuid do |t|
      t.uuid :featured_model_ids, array: true, null: false, default: []
      t.boolean :featured_random, null: false, default: true

      t.timestamps
    end
  end
end
