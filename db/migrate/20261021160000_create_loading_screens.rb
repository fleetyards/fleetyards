# frozen_string_literal: true

class CreateLoadingScreens < ActiveRecord::Migration[8.1]
  def change
    create_table :loading_screens, id: :uuid do |t|
      t.string :environment, null: false
      t.string :version, null: false
      t.string :name, null: false
      t.string :etag

      t.timestamps
    end

    add_index :loading_screens, %i[version name], unique: true
  end
end
