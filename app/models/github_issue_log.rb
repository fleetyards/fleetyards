# frozen_string_literal: true

# == Schema Information
#
# Table name: github_issue_logs
#
#  id             :uuid             not null, primary key
#  content_digest :string           not null
#  issue_number   :integer
#  task_type      :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_github_issue_logs_on_task_type  (task_type)
#
class GithubIssueLog < ApplicationRecord
  validates :task_type, presence: true
  validates :content_digest, presence: true
end
