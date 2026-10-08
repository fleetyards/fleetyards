# frozen_string_literal: true

class GithubIssueLog < ApplicationRecord
  validates :task_type, presence: true
  validates :report_key, presence: true
  validates :content_digest, presence: true
end
