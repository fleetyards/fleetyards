# frozen_string_literal: true

class GithubIssueCreator
  def initialize(task_type:, title:, body:)
    @task_type = task_type
    @title = title
    @body = body
  end

  def run
    digest = Digest::SHA256.hexdigest(@body)

    last_log = GithubIssueLog.where(task_type: @task_type).order(created_at: :desc).first

    return if last_log&.content_digest == digest

    issue = client.create_issue(repo, @title, @body)

    GithubIssueLog.create!(
      task_type: @task_type,
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
