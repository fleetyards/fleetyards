# frozen_string_literal: true

module Presence
  # Tells everybody entitled to know that one user came online or went offline.
  #
  # The message is two fields rather than a rendered member, because the fan-out
  # is what makes this expensive: a user in ten fleets reaches up to 702
  # co-members, and 702 jbuilder renders of a record that did not change is the
  # wrong shape for a change of state.
  class BroadcastTransitionJob < ::ApplicationJob
    sidekiq_options queue: "default", retry: 3

    def perform(user_id, online)
      user = ::User.find_by(id: user_id)
      return if user.blank?

      payload = {
        userId: user.id,
        online: online,
        lastActiveAt: user.last_active_at&.utc&.iso8601
      }

      # Unredacted and ungated: an admin already sees email, sign-in IPs and
      # sign-in counts, and the admin fan-out is a handful of recipients rather
      # than the roster's hundreds.
      broadcast_to_admins(payload)

      return unless Flipper.enabled?(:online_status, user)

      # Sent even when the answer is "offline" because the switch itself
      # broadcasts through here: somebody who turns their status off while
      # connected has to disappear from the rosters that are already showing
      # them, and an omitted message would leave the dot green.
      broadcast_to_peers(user, payload.merge(online: online && user.show_online_status?))
    end

    private def broadcast_to_peers(user, payload)
      ::User.where(id: peer_ids(user)).find_each do |peer|
        broadcast_safely(UserPresenceChannel, peer, payload)
      end
    end

    private def broadcast_to_admins(payload)
      ::AdminUser.find_each do |admin_user|
        broadcast_safely(AdminPresenceChannel, admin_user, payload)
      end
    end

    # Co-members of every fleet the user has actually joined, and the far end of
    # every accepted friendship. `partner_ids_for` reads both `requester_id` and
    # `addressee_id`, because a friendship is an unordered pair rather than one
    # foreign key — and it selects a CASE expression, so it composes as a
    # subquery rather than answering `pluck(:id)`.
    private def peer_ids(user)
      fleet_ids = ::FleetMembership.kept.accepted.where(user_id: user.id).select(:fleet_id)

      co_member_ids = ::FleetMembership.kept.accepted
        .where(fleet_id: fleet_ids)
        .where.not(user_id: user.id)
        .distinct
        .pluck(:user_id)

      friend_ids = ::User.where(id: ::Friendship.partner_ids_for(user)).pluck(:id)

      co_member_ids | friend_ids
    end

    private def broadcast_safely(channel, recipient, payload)
      channel.broadcast_to(recipient, payload)
    rescue => e
      Rails.logger.error(
        "[Presence::BroadcastTransitionJob] #{channel} broadcast to " \
        "#{recipient.class.name}##{recipient.id} failed: #{e.class}: #{e.message}"
      )
    end
  end
end
