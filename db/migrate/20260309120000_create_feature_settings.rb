# frozen_string_literal: true

class CreateFeatureSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :feature_settings, id: :uuid do |t|
      t.string :feature_name, null: false
      t.boolean :self_service, default: false, null: false

      t.timestamps
    end

    add_index :feature_settings, :feature_name, unique: true
  end
end
