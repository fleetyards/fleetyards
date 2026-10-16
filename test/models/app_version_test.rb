# frozen_string_literal: true

require "test_helper"

class AppVersionTest < ActiveSupport::TestCase
  test ".payload carries the live version and no announcement when none is published" do
    create(:announcement, :with_link)

    assert_equal(
      {version: Fleetyards::VERSION, codename: Fleetyards::CODENAME},
      AppVersion.payload
    )
  end

  test ".payload points at the newest published announcement with a link" do
    create(:announcement, :published, :with_link, title: "Older", published_at: 2.days.ago)
    newest = create(:announcement, :published, :with_link, title: "Newest", published_at: 1.day.ago)
    create(:announcement, :published, title: "Without link", published_at: 1.hour.ago)

    assert_equal(
      {title: "Newest", link: newest.absolute_link, publishedAt: newest.published_at.utc.iso8601},
      AppVersion.payload[:announcement]
    )
  end
end
