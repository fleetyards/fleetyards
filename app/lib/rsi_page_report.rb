# frozen_string_literal: true

# A sync in someone's browser met an RSI page its parser does not recognise.
# Those pages need the user's RSI session, so a real sync is the only thing that
# can notice RSI changing them -- and the parser is what needs fixing, not the
# user's hangar.
#
# The notification names the page and the check that failed, and its details
# are what the parser tripped on, in RSI's labels and markup, without item
# titles or custom names: it reaches everyone who watches the RSI status. Each
# hangar report links the sync it came from, holding the pledges the parser
# could not read, which only admins who see imports can open -- the same admins
# who already see every pledge a sync reads. A sync that read the rest of the
# page finished and brings its own import; one that stopped sent nothing, so a
# failed one is recorded in its place.
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
  # each user may trip on different markup. The newest ones are kept, each with
  # the page and extension version it came from.
  MAX_DETAILS = 30

  MAX_DETAIL_LENGTH = 200

  DETAIL_LINE = /\A  - `([^`]+)`/

  EXTENSION_VERSION = /\A[0-9A-Za-z.+-]{1,32}\z/

  LATEST_PAGE_LINE = /\A- Latest page: (\d+)\z/

  LATEST_EXTENSION_LINE = /\A- Latest extension: `([^`]+)`\z/

  MAX_MARKUP_PLEDGES = 5

  def self.record!(page:, check:, user: nil, page_number: nil, extension_version: nil, details: nil, markup: nil, import: nil)
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
    details = Array(details).filter_map { |detail| clean_detail(detail) }.uniq
    context = [
      ("page #{page_number}" if page_number),
      ("extension `#{extension_version}`" if extension_version)
    ].compact
    stopped = import.nil?
    import ||= (record_import(user:, check:, page_number:, extension_version:, details:, markup:) if page == "hangar")
    context << "[import](#{import_path(import)})" if import

    new_lines = details.map do |detail|
      "  - `#{detail}`#{" (#{context.join(", ")})" if context.any?}"
    end

    AdminNotification.notify!(
      type: :rsi_markup_changed,
      title: "RSI #{page} page not recognised (#{check})",
      body: ->(earlier_body) {
        earlier = earlier_body.to_s.lines.map(&:chomp)
        earlier_lines = earlier.select do |line|
          (detail = line[DETAIL_LINE, 1]) && !details.include?(detail)
        end
        detail_lines = (earlier_lines + new_lines).last(MAX_DETAILS)
        # A report without them keeps what an earlier one recorded, which the
        # earlier details still cite.
        latest_page = page_number || earlier.filter_map { |line| line[LATEST_PAGE_LINE, 1] }.first
        latest_extension = extension_version || earlier.filter_map { |line| line[LATEST_EXTENSION_LINE, 1] }.first

        [
          if stopped
            "A #{page} sync stopped on a page its parser does not recognise."
          else
            "A #{page} sync could not read every item. It finished and left unmatched ships as they were."
          end,
          "- Check: `#{check}`",
          ("- Latest page: #{latest_page}" if latest_page),
          ("- Latest extension: `#{latest_extension}`" if latest_extension),
          ("- Details:" if detail_lines.any?),
          *detail_lines
        ].compact.join("\n")
      },
      severity: :error,
      link: (import_path(import) if import),
      record: import,
      # Kept apart from a sync that stopped on the same check: the headline
      # says which happened, and would otherwise speak for both.
      dedupe_key: [page, check, ("finished" unless stopped)].compact.join(":")
    )
  end

  # The sync stopped before it sent anything, so this is the only record of it,
  # in the user's import history as well as the admins'.
  def self.record_import(user:, check:, page_number:, extension_version:, details:, markup:)
    return unless user

    unread_page = {check:, page_number:, details:, markup: Array(markup).first(MAX_MARKUP_PLEDGES)}.compact
    import = Imports::HangarSync.create!(
      user:,
      import_data: {unread_pages: [unread_page]}.to_json,
      info: "RSI hangar page #{page_number || "?"} not recognised (#{[check, ("extension #{extension_version}" if extension_version)].compact.join(", ")})"
    )
    import.fail!
    import
  end
  private_class_method :record_import

  def self.import_path(import)
    "/maintenance/imports/#{import.id}"
  end
  private_class_method :import_path

  # The admin notification renders a detail as inline code.
  def self.clean_detail(detail)
    detail.to_s.tr("`", " ").squish.first(MAX_DETAIL_LENGTH).strip.presence
  end
  private_class_method :clean_detail
end
