# frozen_string_literal: true

class AddShowOnlineStatusToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :show_online_status, :boolean, default: true, null: false
  end
end
