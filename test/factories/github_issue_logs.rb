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
FactoryBot.define do
  factory :github_issue_log do
    task_type { "paints_import" }
    content_digest { "digest" }
    issue_number { 1 }
  end
end
