# frozen_string_literal: true

# Single sink for the recurring reports background jobs produce. Every run lands
# in the admin notification center; a GitHub issue is only opened when the
# report contains something a human has to act on, so clean runs stop opening
# issues nobody can close.
class AdminReport
  def self.deliver(task_type:, title:, body:, actionable:, link: nil, record: nil)
    new(task_type:, title:, body:, actionable:, link:, record:).deliver
  end

  def initialize(task_type:, title:, body:, actionable:, link: nil, record: nil)
    @task_type = task_type.to_sym
    @title = title
    @body = body
    @actionable = actionable
    @link = link
    @record = record
  end

  def deliver
    AdminNotification.notify!(
      type: @task_type,
      title: @title,
      body: @body,
      severity: @actionable ? :warning : :info,
      link: @link,
      record: @record,
      dedupe_key: Digest::SHA256.hexdigest(@body.to_s)
    )

    return unless @actionable

    GithubIssueCreator.new(task_type: @task_type.to_s, title: @title, body: @body).run
  end
end
