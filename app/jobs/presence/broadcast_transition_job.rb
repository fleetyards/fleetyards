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

    class BroadcastFailed < StandardError; end

    # A socket opening or closing.
    REASON_CONNECTION = "connection"

    # The user moving `show_online_status` themselves. The only thing that
    # reaches the peers of somebody who has opted out.
    REASON_PREFERENCE = "preference"

    # The state is read here rather than carried in, so the message always says
    # what is true when it is sent.
    #
    # It has to be: a job that partially failed is retried, and Sidekiq's third
    # backoff lands well past the grace period, so a replayed `online: true`
    # could arrive after the offline transition it preceded and leave the dot
    # green for somebody who has gone. Publishing current state instead means
    # any retry, in any order, converges on the truth. Detecting the transition
    # stays where it belongs — in the reconcile and in `Connection#connect`.
    def perform(user_id, reason = REASON_CONNECTION)
      user = ::User.find_by(id: user_id)
      return if user.blank?

      payload = {
        userId: user.id,
        online: ::UserPresence.online?(user.id),
        lastActiveAt: user.last_active_at&.utc&.iso8601
      }

      failures = []

      broadcast_to_admins(payload, failures)
      broadcast_to_peers(user, payload, reason, failures)

      return if failures.empty?

      # Raised after the whole fan-out rather than at the first failure, so one
      # dead recipient does not cost every recipient after it. Sidekiq then
      # retries the job: a presence message is idempotent — a client applying
      # the same state twice is a no-op — so the duplicates a retry sends cost
      # nothing, and without the raise a swallowed failure would leave a dot
      # stale until the next transition or a reload.
      raise BroadcastFailed, "#{failures.size} recipient(s) not reached: #{failures.first(5).join(", ")}"
    end

    # Nothing at all for somebody who has opted out, except the one correction
    # the switch itself sends.
    #
    # Emitting `online: false` on every connect and disconnect would leak
    # exactly what the switch hides: the message arrives at the moment the
    # socket opens or closes, so a peer watching their own cable could read the
    # timing off it and infer the activity the setting is meant to conceal.
    private def broadcast_to_peers(user, payload, reason, failures)
      visible = user.show_online_status?
      return unless visible || reason == REASON_PREFERENCE

      peer_payload = payload.merge(online: payload[:online] && visible)

      ::User.where(id: peer_ids(user)).find_each do |peer|
        # Per recipient, which is how the REST field and the UI are gated too.
        # Gating on the subject instead would leave a reader inside the rollout
        # holding a dot that never updates for a subject outside it, and would
        # send messages to readers whose UI cannot show them.
        next unless flipper.enabled?(:online_status, peer)

        broadcast_safely(UserPresenceChannel, peer, peer_payload, failures)
      end
    end

    # Unredacted and ungated: an admin already sees email, sign-in IPs and
    # sign-in counts, and the admin fan-out is a handful of recipients rather
    # than the roster's hundreds.
    private def broadcast_to_admins(payload, failures)
      ::AdminUser.find_each do |admin_user|
        broadcast_safely(AdminPresenceChannel, admin_user, payload, failures)
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

    # An instance of its own, memoizing, scoped to this job object.
    #
    # The gate is read per recipient, and against the ActiveRecord adapter that
    # is two queries each — 1404 of them for the worst-case roster. Flipper
    # memoizes for the duration of a web request but not inside a job, and
    # toggling the global adapter would reach every other Sidekiq thread, so the
    # cache belongs here: fifty actors cost four queries.
    private def flipper
      @flipper ||= begin
        adapter = ::Flipper::Adapters::Memoizable.new(::Flipper.adapter)
        adapter.memoize = true
        ::Flipper.new(adapter)
      end
    end

    private def broadcast_safely(channel, recipient, payload, failures)
      channel.broadcast_to(recipient, payload)
    rescue => e
      failures << "#{channel}##{recipient.id} (#{e.class})"

      Rails.logger.error(
        "[Presence::BroadcastTransitionJob] #{channel} broadcast to " \
        "#{recipient.class.name}##{recipient.id} failed: #{e.class}: #{e.message}"
      )
    end
  end
end
