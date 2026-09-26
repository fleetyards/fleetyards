# frozen_string_literal: true

# Single sink for the recurring reports background jobs produce. Every run lands
# in the admin notification center; a GitHub issue is only opened when the
# report contains something a human has to act on, so clean runs stop opening
# issues nobody can close.
#
# `github_issue: false` for a report whose to-do list is already worked through
# in the admin UI. There the issue is pure duplication: it restates a list that
# has its own page, and closing it is a second chore on top of the first.
#
# `notification_body` for a report whose useful content moves every run, such as
# sync counts. `body` stays the issue text and the dedupe key, so a volatile
# notification body neither opens a fresh issue nor a fresh inbox row per run.
class AdminReport
  def self.deliver(task_type:, title:, body:, actionable:, notification_body: nil, link: nil, record: nil, report_key: nil, github_issue: true)
    new(task_type:, title:, body:, actionable:, notification_body:, link:, record:, report_key:, github_issue:).deliver
  end

  def initialize(task_type:, title:, body:, actionable:, notification_body: nil, link: nil, record: nil, report_key: nil, github_issue: true)
    @task_type = task_type.to_sym
    @title = title
    @body = body
    @notification_body = notification_body
    @actionable = actionable
    @link = link
    @record = record
    @report_key = report_key
    @github_issue = github_issue
  end

  def deliver
    AdminNotification.notify!(
      type: @task_type,
      title: @title,
      body: @notification_body || @body,
      severity: @actionable ? :warning : :info,
      link: @link,
      record: @record,
      dedupe_key: Digest::SHA256.hexdigest(@body.to_s)
    )

    return unless @actionable && @github_issue

    GithubIssueCreator.new(
      task_type: @task_type.to_s,
      report_key: @report_key,
      title: @title,
      body: @body
    ).run
  end
end
