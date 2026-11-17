# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class AttachRemoteAvatarJobTest < ActiveSupport::TestCase
  URL = "https://example.com/avatar.png"

  StorageUnavailable = Class.new(StandardError)

  test "attaches the provider's picture" do
    user = create(:user)
    stub_request(:get, URL).to_return(status: 200, body: file_fixture("test.png").binread, headers: {"Content-Type" => "image/png"})

    AttachRemoteAvatarJob.new.perform(user.id, URL)

    assert_predicate user.reload.avatar, :attached?
  end

  test "a storage outage leaves no avatar behind for the retry to mistake as stored" do
    user = create(:user)
    stub_request(:get, URL).to_return(status: 200, body: file_fixture("test.png").binread)
    ActiveStorage::Blob.service.stubs(:upload).raises(StorageUnavailable)

    assert_raises(StorageUnavailable) do
      AttachRemoteAvatarJob.new.perform(user.id, URL)
    end

    assert_not_predicate user.reload.avatar, :attached?
  end

  # The URL here points nowhere, and reaching it would fail the test.
  test "a picture the app will not store is passed over without fetching it" do
    user = create(:user)

    AttachRemoteAvatarJob.new.perform(user.id, "https://example.com/avatar.svg")

    assert_not_predicate user.reload.avatar, :attached?
  end

  test "a picture the provider no longer serves is given up on" do
    user = create(:user)
    stub_request(:get, URL).to_return(status: 404)

    assert_nothing_raised { AttachRemoteAvatarJob.new.perform(user.id, URL) }
    assert_not_predicate user.reload.avatar, :attached?
  end

  test "an avatar the user already has is kept" do
    user = create(:user)
    user.avatar.attach(io: file_fixture("test.png").open, filename: "mine.png", content_type: "image/png")

    AttachRemoteAvatarJob.new.perform(user.id, URL)

    assert_equal "mine.png", user.reload.avatar.filename.to_s
  end
end
