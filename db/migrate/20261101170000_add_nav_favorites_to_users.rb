# frozen_string_literal: true

class AddNavFavoritesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :nav_favorites, :string, array: true, default: [], null: false
  end
end
