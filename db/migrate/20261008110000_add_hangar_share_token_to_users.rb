# frozen_string_literal: true

class AddHangarShareTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :hangar_share_token, :string
    add_index :users, :hangar_share_token, unique: true
  end
end
