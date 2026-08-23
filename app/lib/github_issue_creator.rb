# frozen_string_literal: true

class GithubIssueCreator
  # One task type can deliver more than one report -- the commodity sync sends
  # both its mapping and its price result under "uex_commodity_prices_import".
  # The dedupe below only ever looks at the newest log, so the reports need
  # separate keys or each run reads the other one's digest as "last seen" and
  # opens a duplicate issue for both.
  def initialize(task_type:, title:, body:, report_key: nil)
    @task_type = task_type
    @report_key = report_key.presence || task_type
    @title = title
    @body = body
  end

  def run
    return if Rails.application.credentials.github_token.blank?

    digest = Digest::SHA256.hexdigest(@body)

    last_log = GithubIssueLog.where(report_key: @report_key).order(created_at: :desc).first

    return if last_log&.content_digest == digest

    issue = client.create_issue(repo, @title, @body)

    GithubIssueLog.create!(
      task_type: @task_type,
      report_key: @report_key,
      content_digest: digest,
      issue_number: issue[:number]
    )
  end

  private def client
    @client ||= Octokit::Client.new(access_token: Rails.application.credentials.github_token)
  end

  private def repo
    Rails.configuration.app.github_repo
  end
end
