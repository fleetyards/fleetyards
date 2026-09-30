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
    # The whole JSON, leaving room for the encryption overhead under 4 KB.
    MAX_BYTES = 3_500

    def initialize(notification)
      @notification = notification
    end

    # Measured as the JSON that is sent, since escaping can grow it well past
    # the text's own bytes (`&` is six of them, a quote two). The link is not
    # ours to cut, so an overlong one falls back to the site; after that the
    # body gives way, then the title.
    def to_h
      payload = {
        title: @notification.title.to_s.truncate_bytes(TITLE_MAX_BYTES),
        body: body,
        url: url,
        tag: tag,
        notificationId: @notification.id
      }.compact

      payload[:url] = FRONTEND_ENDPOINT unless fits?(payload)
      shrink(payload, :body)
      shrink(payload, :title)
      payload
    end

    private def fits?(payload)
      overflow(payload) <= 0
    end

    private def overflow(payload)
      payload.to_json.bytesize - MAX_BYTES
    end

    # The longest cut that fits. Escaping makes the JSON grow unevenly with
    # the text, so the cut is searched for rather than computed.
    private def shrink(payload, key)
      text = payload[key]
      return if text.blank? || fits?(payload)

      shortest = 0
      longest = text.bytesize
      while shortest < longest
        candidate = (shortest + longest + 1) / 2
        if fits?(payload.merge(key => text.truncate_bytes(candidate)))
          shortest = candidate
        else
          longest = candidate - 1
        end
      end

      payload[key] = text.truncate_bytes(shortest)
      payload.delete(:body) if key == :body && payload[:body].blank?
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

    # A path is the site's; an absolute link has to be a real http(s) URL.
    # Anything else -- announcement links are free text -- opens the site.
    private def url
      link = @notification.link.to_s.strip
      return "#{FRONTEND_ENDPOINT}#{link}" if link.start_with?("/") && !link.start_with?("//")

      uri = URI.parse(link)
      return link if uri.is_a?(URI::HTTP) && uri.host.present?

      FRONTEND_ENDPOINT
    rescue URI::Error
      FRONTEND_ENDPOINT
    end

    # A later push with the same tag replaces the banner instead of stacking a
    # second one, so a burst on one record collapses into one.
    private def tag
      [@notification.notification_type, @notification.record_id || @notification.id].join(":")
    end
  end
end
