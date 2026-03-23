# frozen_string_literal: true

class CreateGithubIssueLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :github_issue_logs, id: :uuid do |t|
      t.string :task_type, null: false
      t.string :content_digest, null: false
      t.integer :issue_number

      t.timestamps
    end

    add_index :github_issue_logs, :task_type
  end
end
