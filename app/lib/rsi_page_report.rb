# frozen_string_literal: true

# A sync in someone's browser met an RSI page its parser does not recognise.
# Those pages need the user's RSI session, so a real sync is the only thing that
# can notice RSI changing them -- and the parser is what needs fixing, not the
# user's hangar.
#
# A report names the page and the check that failed, never the page itself: the
# pledge pages are the user's purchase history. Its details are what the parser
# tripped on, in RSI's labels and markup, without item titles or custom names.
class RsiPageReport
  PAGES = %w[hangar buyback].freeze

  CHECKS = %w[
    missing_list
    missing_pledge_ids
    missing_kinds
    unknown_kinds
    missing_entries
    unparsed_entries
  ].freeze

  # Anyone signed in can send one, so a user counts once per page and check in
  # this window: enough to show how many users a change stops, without letting
  # one of them reopen the notification as fast as the admins can read it.
  REPORT_INTERVAL = 1.hour

  # Repeats of one check add their details to the unread notification, since
  # each user may trip on different markup. The newest ones are kept.
  MAX_DETAILS = 30

  MAX_DETAIL_LENGTH = 200

  DETAIL_LINE = /\A  - `(.+)`\z/

  EXTENSION_VERSION = /\A[0-9A-Za-z.+-]{1,32}\z/

  def self.record!(page:, check:, user: nil, page_number: nil, extension_version: nil, details: nil)
    if user
      first = Rails.cache.write(
        "rsi_page_report/#{user.id}/#{page}/#{check}", true,
        expires_in: REPORT_INTERVAL, unless_exist: true
      )
      return unless first
    end

    # The input schema's patterns anchor per line, so a value spanning several
    # lines can pass them. Both end up in markdown the admins read.
    extension_version = extension_version.to_s[EXTENSION_VERSION]
    details = Array(details).filter_map { |detail| clean_detail(detail) }

    AdminNotification.notify!(
      type: :rsi_markup_changed,
      title: "RSI #{page} page not recognised (#{check})",
      body: ->(earlier_body) {
        earlier = earlier_body.to_s.lines.filter_map { |line| line.chomp[DETAIL_LINE, 1] }
        all_details = (earlier + Array(details)).reverse.uniq.reverse.last(MAX_DETAILS)

        [
          "A #{page} sync stopped on a page its parser does not recognise.",
          "- Check: `#{check}`",
          ("- Page: #{page_number}" if page_number),
          ("- Extension: `#{extension_version}`" if extension_version),
          ("- Details:" if all_details.any?),
          *all_details.map { |detail| "  - `#{detail}`" }
        ].compact.join("\n")
      },
      severity: :error,
      dedupe_key: "#{page}:#{check}"
    )
  end

  # The admin notification renders a detail as inline code.
  def self.clean_detail(detail)
    detail.to_s.tr("`", " ").squish.first(MAX_DETAIL_LENGTH).strip.presence
  end
  private_class_method :clean_detail
end
