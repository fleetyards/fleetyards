# frozen_string_literal: true

class AddReportKeyToGithubIssueLogs < ActiveRecord::Migration[8.1]
  def up
    add_column :github_issue_logs, :report_key, :string

    # One task type can deliver more than one report, and the dedupe compares a
    # body against the newest log for its key. Every log written so far came
    # from a job delivering a single report, so its task type is that key.
    execute "UPDATE github_issue_logs SET report_key = task_type WHERE report_key IS NULL"

    change_column_null :github_issue_logs, :report_key, false
    add_index :github_issue_logs, :report_key
  end

  def down
    remove_index :github_issue_logs, :report_key
    remove_column :github_issue_logs, :report_key
  end
end
