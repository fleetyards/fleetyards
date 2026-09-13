# frozen_string_literal: true

module Relationships
  # Who is told what about a request.
  #
  # Two events per relationship, not four. A decline writes nothing and an
  # ignore obviously writes nothing -- an ignore that pings the sender is not an
  # ignore, and if declining were the only answer that notified, it would be the
  # more hostile of the two. A refusal is visible in the sender's own list,
  # which is where somebody who wants to know can look.
  #
  # A friendship is told to one person. An alliance is told to whoever can act
  # on it, which is a privilege walk rather than a single user.
  class Notifier
    def initialize(relationship)
      @relationship = relationship
    end

    # The addressee has something to answer.
    def requested
      notify(@relationship.addressee, :received, about: @relationship.requester)
    end

    # The requester's request landed.
    def accepted
      notify(@relationship.requester, :accepted, about: @relationship.addressee)
    end

    private def notify(party, event, about:)
      type = :"#{prefix}_request_#{event}"

      recipients_for(party).each do |user|
        ::Notification.notify!(
          user: user,
          type: type,
          title: I18n.t("notifications.#{type}.title", **title_args(about, party)),
          link: link_for(party),
          record: @relationship
        )
      end
    end

    # A user speaks for themselves. A fleet is spoken for by the members who
    # could actually answer -- telling the whole roster about an alliance nobody
    # but an admin can act on is noise.
    private def recipients_for(party)
      return [party] if party.is_a?(::User)

      party.fleet_memberships.kept.accepted.includes(:fleet_role, :user)
        .select { |membership| membership.has_access?(["fleet:manage", "fleet:allies:manage"]) }
        .filter_map(&:user)
    end

    private def prefix
      @relationship.is_a?(::FleetAlliance) ? "fleet_ally" : "friend"
    end

    private def title_args(about, party)
      return {username: about.username} if about.is_a?(::User)

      {fleet: about.name, own_fleet: party.name}
    end

    private def link_for(party)
      helpers = ::Rails.application.routes.url_helpers

      return helpers.frontend_friends_path if party.is_a?(::User)

      helpers.frontend_fleet_allies_path(party.slug)
    end
  end
end
