# frozen_string_literal: true

class CreateFeedbackReplies < ActiveRecord::Migration[8.1]
  def change
    create_table :feedback_replies, id: :uuid do |t|
      t.references :feedback, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      # Kept apart from the admin: removing an admin must not turn their
      # replies into ones the user appears to have written.
      t.boolean :from_admin, null: false, default: false
      t.references :admin_user, type: :uuid, null: true,
        foreign_key: {on_delete: :nullify}

      t.text :body, null: false

      t.timestamps
    end
  end
end
