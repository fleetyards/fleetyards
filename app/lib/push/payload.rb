# frozen_string_literal: true

module Push
  # What a push carries to the service worker, which turns it into a system
  # notification. Push services refuse a payload over 4 KB once encrypted, so
  # the body is cut well short of that: a notification banner shows a few lines
  # at most, and the link opens the rest. In bytes, not characters: an emoji is
  # four of them.
  class Payload
    include MarkdownHelper

    TITLE_MAX_BYTES = 400
    BODY_MAX_BYTES = 2_000

    def initialize(notification)
      @notification = notification
    end

    def to_h
      {
        title: @notification.title.to_s.truncate_bytes(TITLE_MAX_BYTES),
        body: body,
        url: url,
        tag: tag,
        notificationId: @notification.id
      }.compact
    end

    def to_json(*)
      to_h.to_json
    end

    # The body is markdown, which a system notification shows as plain text.
    private def body
      text = @notification.body.presence
      return if text.nil?

      plain = ActionController::Base.helpers.strip_tags(render_markdown(text)).squish
      CGI.unescapeHTML(plain).truncate_bytes(BODY_MAX_BYTES).presence
    end

    private def url
      path = @notification.link.presence
      return FRONTEND_ENDPOINT if path.nil?
      return path if path.start_with?("http")

      "#{FRONTEND_ENDPOINT}#{path}"
    end

    # A later push with the same tag replaces the banner instead of stacking a
    # second one, so a burst on one record collapses into one.
    private def tag
      [@notification.notification_type, @notification.record_id || @notification.id].join(":")
    end
  end
end
