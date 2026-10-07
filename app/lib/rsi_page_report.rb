# frozen_string_literal: true

# A sync in someone's browser met an RSI page its parser does not recognise.
# Those pages need the user's RSI session, so a real sync is the only thing that
# can notice RSI changing them -- and the parser is what needs fixing, not the
# user's hangar.
#
# A report names the page and the check that failed, never the page itself: the
# pledge pages are the user's purchase history.
class RsiPageReport
  PAGES = %w[hangar buyback].freeze

  CHECKS = %w[
    missing_list
    missing_pledge_ids
    missing_kinds
    missing_entries
    unparsed_entries
  ].freeze

  # Anyone signed in can send one, so a user counts once per page and check in
  # this window: enough to show how many users a change stops, without letting
  # one of them reopen the notification as fast as the admins can read it.
  REPORT_INTERVAL = 1.hour

  def self.record!(page:, check:, user: nil, page_number: nil, extension_version: nil)
    if user
      first = Rails.cache.write(
        "rsi_page_report/#{user.id}/#{page}/#{check}", true,
        expires_in: REPORT_INTERVAL, unless_exist: true
      )
      return unless first
    end

    AdminNotification.notify!(
      type: :rsi_markup_changed,
      title: "RSI #{page} page not recognised (#{check})",
      body: [
        "A #{page} sync stopped on a page its parser does not recognise.",
        "- Check: `#{check}`",
        ("- Page: #{page_number}" if page_number),
        ("- Extension: `#{extension_version}`" if extension_version.present?)
      ].compact.join("\n"),
      severity: :error,
      dedupe_key: "#{page}:#{check}"
    )
  end
end
