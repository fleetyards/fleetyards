# frozen_string_literal: true

class AddRepliesCountToFeedbacks < ActiveRecord::Migration[8.1]
  def change
    add_column :feedbacks, :replies_count, :integer, null: false, default: 0

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE feedbacks
          SET replies_count = (
            SELECT COUNT(*) FROM feedback_replies WHERE feedback_replies.feedback_id = feedbacks.id
          )
        SQL
      end
    end
  end
end
