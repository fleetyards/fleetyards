# frozen_string_literal: true

require "test_helper"

class GithubIssueCreatorTest < ActiveSupport::TestCase
  setup do
    Rails.application.credentials.stubs(:github_token).returns("token")

    @client = mock("octokit")
    Octokit::Client.stubs(:new).returns(@client)
  end

  test "#run opens an issue and records the body it was opened for" do
    @client.expects(:create_issue).once.returns({number: 42})

    creator(body: "something to fix").run

    log = GithubIssueLog.sole
    assert_equal "uex_commodity_prices", log.report_key
    assert_equal 42, log.issue_number
  end

  test "#run does not reopen an issue for a body it already opened" do
    @client.expects(:create_issue).once.returns({number: 42})

    2.times { creator(body: "something to fix").run }

    assert_equal 1, GithubIssueLog.count
  end

  test "#run opens a fresh issue once the body changes" do
    @client.expects(:create_issue).twice.returns({number: 42}, {number: 43})

    creator(body: "something to fix").run
    creator(body: "something else to fix").run

    assert_equal 2, GithubIssueLog.count
  end

  # Both reports of the commodity sync share one task type. Deduping on the task
  # type alone made each run read the other report's digest as the last one seen,
  # so every run reopened both issues.
  test "#run keeps two reports of one task type from reopening each other" do
    @client.expects(:create_issue).twice.returns({number: 42}, {number: 43})

    2.times do
      creator(report_key: "uex_commodity_mapping", body: "commodities we cannot price").run
      creator(report_key: "uex_commodity_prices", body: "prices we cannot place").run
    end

    assert_equal 2, GithubIssueLog.count
  end

  test "#run falls back to the task type when no report key is given" do
    @client.expects(:create_issue).once.returns({number: 42})

    GithubIssueCreator.new(task_type: "paints_import", title: "Paints", body: "a paint").run

    assert_equal "paints_import", GithubIssueLog.sole.report_key
  end

  test "#run does nothing without a github token" do
    Rails.application.credentials.stubs(:github_token).returns(nil)
    @client.expects(:create_issue).never

    creator(body: "something to fix").run

    assert_empty GithubIssueLog.all
  end

  private def creator(body:, report_key: "uex_commodity_prices")
    GithubIssueCreator.new(
      task_type: "uex_commodity_prices_import",
      report_key:,
      title: "UEX Commodity Sync",
      body:
    )
  end
end
