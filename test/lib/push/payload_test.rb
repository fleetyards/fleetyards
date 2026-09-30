# frozen_string_literal: true

require "test_helper"

module Push
  class PayloadTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
    end

    def payload(**attrs)
      notification = Notification.create!(user: @user, notification_type: :fleet_invite, title: "Invited", **attrs)
      Payload.new(notification)
    end

    test "carries the title, the link as an absolute URL and the notification id" do
      subject = payload(link: "/fleets/invites")

      assert_equal "Invited", subject.to_h[:title]
      assert_equal "#{FRONTEND_ENDPOINT}/fleets/invites", subject.to_h[:url]
      assert subject.to_h[:notificationId].present?
    end

    test "a notification without a link opens the site" do
      assert_equal FRONTEND_ENDPOINT, payload.to_h[:url]
    end

    test "the body is plain text, not markdown" do
      subject = payload(body: "**Bold** & [a link](https://example.com)\n\n- one\n- two")

      assert_equal "Bold & a link one two", subject.to_h[:body]
    end

    test "a blank body is left out" do
      refute_includes payload(body: "").to_h.keys, :body
    end

    test "a burst on one record shares a tag" do
      membership = create(:fleet_membership)
      first = payload(record: membership)
      second = payload(record: membership)

      assert_equal first.to_h[:tag], second.to_h[:tag]
      assert_equal "fleet_invite:#{membership.id}", first.to_h[:tag]
    end

    # Push services refuse more than 4 KB once encrypted, which adds a little
    # over 100 bytes.
    test "a long body stays well under the push size limit" do
      subject = payload(title: "🚀" * 500, body: "🚀" * 5000, link: "/fleets/#{"a" * 100}/events/#{SecureRandom.uuid}")

      assert_operator subject.to_json.bytesize, :<, 3_900
    end

    test "an overlong link falls back to the site so the push still fits" do
      subject = payload(title: "🚀" * 500, body: "🚀" * 5000, link: "/#{"a" * 5000}")

      assert_equal FRONTEND_ENDPOINT, subject.to_h[:url]
      assert_operator subject.to_json.bytesize, :<=, Payload::MAX_BYTES
    end

    test "a body that grows when escaped still fits" do
      subject = payload(title: "&" * 400, body: "&\"" * 2_000)

      assert_operator subject.to_json.bytesize, :<=, Payload::MAX_BYTES
      assert subject.to_h[:body].present?
    end

    test "an absolute link is kept" do
      assert_equal "https://robertsspaceindustries.com/comm-link", payload(link: "https://robertsspaceindustries.com/comm-link").to_h[:url]
    end

    %w[http-not-a-url javascript:alert(1) //evil.example/path mailto:someone].each do |link|
      test "#{link} opens the site instead" do
        assert_equal FRONTEND_ENDPOINT, payload(link:).to_h[:url]
      end
    end
  end
end
