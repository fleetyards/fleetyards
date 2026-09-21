# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: announcements
#
#  id               :uuid             not null, primary key
#  body             :text             not null
#  discord_parts    :text             default([]), not null, is an Array
#  icon             :string
#  last_tested_at   :datetime
#  link             :string
#  notify_users     :boolean          default(TRUE), not null
#  post_bluesky     :boolean          default(FALSE), not null
#  post_discord     :boolean          default(FALSE), not null
#  post_x           :boolean          default(FALSE), not null
#  publish_at       :datetime
#  published_at     :datetime
#  recipients_count :integer
#  social_parts     :text             default([]), not null, is an Array
#  status           :string           default("draft"), not null
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  admin_user_id    :uuid
#
# Indexes
#
#  index_announcements_on_publish_at    (publish_at) WHERE ((status)::text = 'scheduled'::text)
#  index_announcements_on_published_at  (published_at)
#  index_announcements_on_status        (status)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
class AnnouncementTest < ActiveSupport::TestCase
  test "requires a title and a body" do
    refute Announcement.new(body: "x").valid?
    refute Announcement.new(title: "x").valid?
    assert Announcement.new(title: "x", body: "y").valid?
  end

  test "requires at least one channel" do
    announcement = Announcement.new(title: "x", body: "y", notify_users: false)

    refute announcement.valid?
    assert_includes announcement.errors.attribute_names, :base

    announcement.post_bluesky = true
    assert announcement.valid?
  end

  test "a scheduled announcement needs a publish_at" do
    announcement = build(:announcement, status: "scheduled")

    refute announcement.valid?

    announcement.publish_at = 1.hour.from_now
    assert announcement.valid?
  end

  # Each part is measured against the platforms the announcement actually
  # selected, and measured the way each of them counts.
  test "each social part is capped by the platforms it is going to" do
    refute build(:announcement, :social, social_parts: ["ok", "x" * 281]).valid?
    assert build(:announcement, post_bluesky: true, social_parts: ["ok", "x" * 300]).valid?
    refute build(:announcement, post_bluesky: true, social_parts: ["x" * 301]).valid?
  end

  # 200 CJK characters are 400 to X and 200 to Bluesky, so the same post is
  # legal on one and refused on the other.
  test "a part is measured the way each platform measures" do
    assert build(:announcement, post_bluesky: true, social_parts: ["公" * 200]).valid?
    refute build(:announcement, post_x: true, social_parts: ["公" * 200]).valid?
  end

  # A limit for a channel nobody selected is noise.
  test "social parts are unmeasured when no social channel is selected" do
    assert build(:announcement, notify_users: true, social_parts: ["x" * 500]).valid?
  end

  test "the error names the platform and which part is too long" do
    announcement = build(:announcement, post_x: true, social_parts: ["ok", "x" * 281])
    announcement.valid?

    message = announcement.errors.full_messages.join
    assert_includes message, "post 2"
    assert_includes message, I18n.t("announcements.channels.x")
  end

  test "each Discord part is capped at a Discord message" do
    refute build(:announcement, discord_parts: ["x" * 2_001]).valid?
    assert build(:announcement, discord_parts: ["x" * 2_000]).valid?
  end

  # A repeatable field leaves empty rows behind when one is removed from the
  # middle, and an empty post is not a post.
  test "blank parts are dropped rather than posted" do
    announcement = create(:announcement, social_parts: ["One", "  ", "", "Two"], discord_parts: [""])

    assert_equal %w[One Two], announcement.social_parts
    assert_empty announcement.discord_parts
  end

  test "#authored_social? and #threaded? follow the parts" do
    refute build(:announcement).authored_social?
    refute build(:announcement, social_parts: ["One"]).threaded?
    assert build(:announcement, social_parts: ["One"]).authored_social?
    assert build(:announcement, social_parts: ["One", "Two"]).threaded?
  end

  test "gets a default icon" do
    assert_equal Announcement::DEFAULT_ICON, create(:announcement).icon
  end

  test "#channels lists in_app alongside the selected social channels" do
    announcement = build(:announcement, :social)

    assert_equal %i[in_app discord bluesky x], announcement.channels
  end

  test "#social_channels leaves out what was not selected" do
    assert_equal %i[bluesky], build(:announcement, post_bluesky: true).social_channels
  end

  test "#publishable? covers draft, scheduled and failed but not published" do
    assert build(:announcement).publishable?
    assert build(:announcement, :scheduled).publishable?
    assert build(:announcement, :failed).publishable?
    refute build(:announcement, :published).publishable?
    refute build(:announcement, status: "publishing").publishable?
  end

  test "#absolute_link resolves a path and leaves a url alone" do
    assert_nil build(:announcement).absolute_link
    assert_equal "https://example.com/x", build(:announcement, link: "https://example.com/x").absolute_link
    assert_equal(
      "https://#{Rails.configuration.app.domain}/fleets/",
      build(:announcement, :with_link).absolute_link
    )
  end

  test "destroying an announcement leaves its notifications without a dangling record" do
    announcement = create(:announcement)
    user = create(:user)
    notification = Notification.notify!(
      user:, type: :announcement, title: "t", body: "b", record: announcement
    )

    announcement.destroy!

    notification.reload
    assert_nil notification.record_id
    assert_nil notification.record_type
    assert_equal "t", notification.title
  end

  test ".due only returns scheduled announcements whose time has passed" do
    due = create(:announcement, status: "scheduled", publish_at: 1.minute.ago)
    create(:announcement, status: "scheduled", publish_at: 1.hour.from_now)
    create(:announcement, :published)

    assert_equal [due], Announcement.due.to_a
  end

  test "a status change reaches every admin" do
    create(:admin_user)
    create(:admin_user)
    announcement = create(:announcement)

    AdminAnnouncementsChannel.expects(:broadcast_to).twice

    announcement.update!(status: :publishing)
  end

  test "an edit that a send did not make is not broadcast" do
    create(:admin_user)
    announcement = create(:announcement)

    AdminAnnouncementsChannel.expects(:broadcast_to).never

    announcement.update!(title: "Renamed")
  end

  # after_commit, so the write it describes has already landed -- taking the
  # send down with the socket would leave an announcement half dispatched.
  test "a broadcast that raises does not take the write with it" do
    create(:admin_user)
    announcement = create(:announcement)

    AdminAnnouncementsChannel.stubs(:broadcast_to).raises(StandardError, "cable down")

    announcement.update!(status: :publishing)

    assert announcement.reload.status_publishing?
  end
end
