# frozen_string_literal: true

class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks, id: :uuid do |t|
      t.references :user, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}

      t.text :message, null: false
      t.string :feature_name
      t.string :page_path

      t.string :aasm_state, null: false, default: "open"

      t.references :resolved_by, type: :uuid, null: true,
        foreign_key: {to_table: :admin_users, on_delete: :nullify}
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :feedbacks, :created_at
    add_index :feedbacks, :feature_name
  end
end
