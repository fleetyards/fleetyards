# frozen_string_literal: true

class GithubIssueCreator
  def initialize(task_type:, title:, body:)
    @task_type = task_type
    @title = title
    @body = body
  end

  def run
    return if Rails.application.credentials.github_token.blank?

    digest = Digest::SHA256.hexdigest(@body)

    last_log = GithubIssueLog.where(task_type: @task_type).order(created_at: :desc).first

    return if last_log&.content_digest == digest

    open_issue = open_issue_for(last_log)

    issue =
      if open_issue
        client.update_issue(repo, open_issue[:number], @title, @body)
      else
        client.create_issue(repo, @title, @body)
      end

    GithubIssueLog.create!(
      task_type: @task_type,
      content_digest: digest,
      issue_number: issue[:number]
    )
  end

  private def open_issue_for(last_log)
    return if last_log&.issue_number.blank?

    issue = client.issue(repo, last_log.issue_number)
    issue if issue[:state] == "open"
  rescue Octokit::NotFound
    nil
  end

  private def client
    @client ||= Octokit::Client.new(access_token: Rails.application.credentials.github_token)
  end

  private def repo
    Rails.configuration.app.github_repo
  end
end
