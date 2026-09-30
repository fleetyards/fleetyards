# frozen_string_literal: true

class CreateMarkdownImages < ActiveRecord::Migration[8.1]
  def change
    create_table :markdown_images, id: :uuid do |t|
      # An image outlives the account that uploaded it: descriptions belong to
      # fleets, not members, and the cleanup job removes what nothing uses.
      t.references :user, type: :uuid, null: true, foreign_key: {on_delete: :nullify}, index: false

      t.timestamps
    end

    add_index :markdown_images, %i[user_id created_at]
  end
end
