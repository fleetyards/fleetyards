# frozen_string_literal: true

class AddRepliesCountToFeedbacks < ActiveRecord::Migration[8.1]
  def change
    add_column :feedbacks, :replies_count, :integer, null: false, default: 0
  end
end
