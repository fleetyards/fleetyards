# frozen_string_literal: true

class AddCalendarFeedTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :calendar_feed_token, :string
    add_index :users, :calendar_feed_token, unique: true
  end
end
