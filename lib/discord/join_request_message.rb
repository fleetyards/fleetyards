# frozen_string_literal: true

module Discord
  # A join request as it reads in the officers' channel: who asked, and a
  # button for each answer. Once answered, the same message says how and the
  # buttons stay in place, disabled, so nobody clicks into a settled request.
  #
  # Always in the default locale: the message is read by every officer, and
  # whoever happens to click it first must not decide its language.
  class JoinRequestMessage
    CUSTOM_ID_PREFIX = "fleet_request"

    ACTION_ROW = 1
    BUTTON = 2
    SUCCESS_STYLE = 3
    DANGER_STYLE = 4

    def self.custom_id(decision, membership_id)
      [CUSTOM_ID_PREFIX, decision, membership_id].join(":")
    end

    # Names the request a click is about and nothing else. Who may answer it
    # is decided again on every click, never read from here.
    def self.parse(custom_id)
      prefix, decision, membership_id = custom_id.to_s.split(":", 3)
      return nil unless prefix == CUSTOM_ID_PREFIX
      return nil unless JoinRequestDecision::DECISIONS.include?(decision)
      return nil if membership_id.blank?

      {decision: decision, membership_id: membership_id}
    end

    # For a request that no longer exists there is nothing to say about it,
    # so the text stays as it was and only the buttons go.
    def self.closed_payload(membership_id)
      {components: new(nil).buttons(membership_id, disabled: true)}
    end

    attr_reader :membership

    def initialize(membership)
      @membership = membership
    end

    def pending_payload
      {content: summary, components: buttons(membership.id, disabled: false)}
    end

    def settled_payload
      {
        content: [summary, outcome].join("\n"),
        components: buttons(membership.id, disabled: true),
        allowed_mentions: {parse: []}
      }
    end

    def buttons(membership_id, disabled:)
      [{
        type: ACTION_ROW,
        components: [
          button(JoinRequestDecision::ACCEPT, SUCCESS_STYLE, membership_id, disabled),
          button(JoinRequestDecision::DECLINE, DANGER_STYLE, membership_id, disabled)
        ]
      }]
    end

    private def button(decision, style, membership_id, disabled)
      {
        type: BUTTON,
        style: style,
        label: t("buttons.#{decision}"),
        custom_id: self.class.custom_id(decision, membership_id),
        disabled: disabled
      }
    end

    private def summary
      t("summary",
        username: Markdown.escape(membership.user.username),
        fleet: Markdown.escape(membership.fleet.name),
        url: "https://#{Rails.configuration.app.domain}/fleets/#{membership.fleet.slug}/members/")
    end

    private def outcome
      state = if membership.accepted?
        "accepted"
      elsif membership.declined?
        "declined"
      else
        return t("closed")
      end

      officer = decided_by
      return t(state) if officer.nil?

      t("#{state}_by", officer: Markdown.escape(officer.username))
    end

    # Read from the version rather than handed in, so every edit of the
    # message names the same officer: a second click on a settled request,
    # or a retry after the first edit failed, would otherwise overwrite the
    # name. Nil when the request was settled without an author on record.
    private def decided_by
      author_id = membership.versions
        .where("jsonb_exists(object_changes::jsonb, ?)", "aasm_state")
        .reorder(created_at: :desc)
        .pick(:author_id)

      author_id && User.find_by(id: author_id)
    end

    private def t(key, **)
      I18n.t("discord.join_request.#{key}", locale: I18n.default_locale, **)
    end
  end
end
