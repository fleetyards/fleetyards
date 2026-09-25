# frozen_string_literal: true

class AddHangarDefaultSortToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :hangar_default_sort, :string
  end
end
