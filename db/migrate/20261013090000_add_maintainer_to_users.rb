# frozen_string_literal: true

class AddMaintainerToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :maintainer, :boolean, default: false, null: false
  end
end
