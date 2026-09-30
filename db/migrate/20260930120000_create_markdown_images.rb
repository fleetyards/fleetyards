# frozen_string_literal: true

class CreateMarkdownImages < ActiveRecord::Migration[8.1]
  def change
    create_table :markdown_images, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false

      t.timestamps
    end

    add_index :markdown_images, %i[user_id created_at]
  end
end
