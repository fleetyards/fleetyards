# frozen_string_literal: true

require "test_helper"

class GithubIssueCreatorTest < ActiveSupport::TestCase
  BODY = "## Missing Models\n\n- **Foo**"
  REPO = Rails.configuration.app.github_repo

  setup do
    Rails.application.credentials.stubs(:github_token).returns("token")
    @client = mock("client")
    GithubIssueCreator.any_instance.stubs(:client).returns(@client)
  end

  def creator(body: BODY)
    GithubIssueCreator.new(task_type: "paints_import", title: "Paints Import Results", body:)
  end

  test "creates an issue and logs it when none exists yet" do
    @client.expects(:create_issue).with(REPO, "Paints Import Results", BODY).returns({number: 100})

    assert_difference -> { GithubIssueLog.count }, 1 do
      creator.run
    end

    log = GithubIssueLog.order(created_at: :desc).first
    assert_equal 100, log.issue_number
    assert_equal Digest::SHA256.hexdigest(BODY), log.content_digest
  end

  test "updates the open issue in place when content changed" do
    create(:github_issue_log, task_type: "paints_import", issue_number: 100, content_digest: "stale")
    @client.expects(:issue).with(REPO, 100).returns({number: 100, state: "open"})
    @client.expects(:update_issue).with(REPO, 100, "Paints Import Results", BODY).returns({number: 100})
    @client.expects(:create_issue).never

    assert_difference -> { GithubIssueLog.count }, 1 do
      creator.run
    end
  end

  test "does nothing when the open issue already has the current content" do
    create(:github_issue_log, task_type: "paints_import", issue_number: 100, content_digest: Digest::SHA256.hexdigest(BODY))
    @client.expects(:issue).with(REPO, 100).returns({number: 100, state: "open"})
    @client.expects(:update_issue).never
    @client.expects(:create_issue).never

    assert_no_difference -> { GithubIssueLog.count } do
      creator.run
    end
  end

  test "creates a replacement when the prior issue is closed even if content is unchanged" do
    create(:github_issue_log, task_type: "paints_import", issue_number: 100, content_digest: Digest::SHA256.hexdigest(BODY))
    @client.expects(:issue).with(REPO, 100).returns({number: 100, state: "closed"})
    @client.expects(:create_issue).with(REPO, "Paints Import Results", BODY).returns({number: 101})

    assert_difference -> { GithubIssueLog.count }, 1 do
      creator.run
    end

    assert_equal 101, GithubIssueLog.order(created_at: :desc).first.issue_number
  end

  test "creates a replacement when the prior issue was deleted" do
    create(:github_issue_log, task_type: "paints_import", issue_number: 100, content_digest: Digest::SHA256.hexdigest(BODY))
    @client.expects(:issue).with(REPO, 100).raises(Octokit::NotFound)
    @client.expects(:create_issue).with(REPO, "Paints Import Results", BODY).returns({number: 101})

    assert_difference -> { GithubIssueLog.count }, 1 do
      creator.run
    end
  end

  test "does nothing without a github token" do
    Rails.application.credentials.stubs(:github_token).returns(nil)
    @client.expects(:create_issue).never
    @client.expects(:update_issue).never

    assert_no_difference -> { GithubIssueLog.count } do
      creator.run
    end
  end

  test "#resolve closes the open issue when one exists" do
    create(:github_issue_log, task_type: "paints_import", issue_number: 100, content_digest: "stale")
    @client.expects(:issue).with(REPO, 100).returns({number: 100, state: "open"})
    @client.expects(:close_issue).with(REPO, 100)

    creator.resolve
  end

  test "#resolve does nothing when the prior issue is already closed" do
    create(:github_issue_log, task_type: "paints_import", issue_number: 100, content_digest: "stale")
    @client.expects(:issue).with(REPO, 100).returns({number: 100, state: "closed"})
    @client.expects(:close_issue).never

    creator.resolve
  end

  test "#resolve does nothing when no issue was ever logged" do
    @client.expects(:issue).never
    @client.expects(:close_issue).never

    creator.resolve
  end

  test "#resolve does nothing without a github token" do
    Rails.application.credentials.stubs(:github_token).returns(nil)
    create(:github_issue_log, task_type: "paints_import", issue_number: 100, content_digest: "stale")
    @client.expects(:close_issue).never

    creator.resolve
  end
end
