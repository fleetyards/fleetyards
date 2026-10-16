# frozen_string_literal: true

# What a client running older assets needs to offer a reload: the version that
# is live now, and the newest announcement it could point at as "what's new".
class AppVersion
  def self.payload
    {
      version: Fleetyards::VERSION,
      codename: Fleetyards::CODENAME,
      announcement: latest_announcement
    }.compact
  end

  # Cached because every client resubscribes within seconds of a deploy, and
  # each subscribe sends this payload.
  def self.latest_announcement
    Rails.cache.fetch("app_version/latest_announcement", expires_in: 1.minute) do
      announcement = Announcement.status_published
        .where.not(link: [nil, ""])
        .where.not(published_at: nil)
        .order(published_at: :desc)
        .first

      next if announcement.blank?

      {
        title: announcement.title,
        link: announcement.absolute_link,
        publishedAt: announcement.published_at.utc.iso8601
      }
    end
  end
end
