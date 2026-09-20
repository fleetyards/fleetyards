# frozen_string_literal: true

# Who is connected right now, as one sorted set in the cable Redis database.
#
# A member is one *connection* rather than one user — four tabs and a phone are
# one presence, and closing one of them must not take the others offline — and
# its score is the unix time that connection stops counting. Every read filters
# on the score, so a connection whose worker was killed is invisible from the
# moment it ages out, whether or not the sweep has run since.
#
# `ActionCable.server.connections` cannot answer this: it is per process, and
# live runs three Puma workers per host, so the socket and the request asking
# about it almost never share one.
class UserPresence
  # Two missed heartbeats. Long enough that a slow beat does not drop a live
  # connection, short enough that a killed worker is forgotten within the two
  # minutes a roster is still being looked at.
  TTL = 90

  # A reload is a disconnect followed by a connect a second later, and emitting
  # both would flap a dot on every co-member's roster. A closing connection
  # keeps counting for this long instead of leaving at once, which covers the
  # reload, the one-of-four-tabs case and the debounce with one mechanism.
  GRACE = 60

  # Three beats inside the TTL.
  HEARTBEAT_INTERVAL = 30

  class << self
    # A connection that has just been accepted. Returns true when this is the
    # user's first live connection *and* nothing has announced them online yet,
    # which is what a reload must not do.
    def connect(user_id, token)
      write { redis.zadd(connections_key, expires_at(TTL), member(user_id, token)) }

      announce(user_id)
    end

    def heartbeat(user_id, token)
      write { redis.zadd(connections_key, expires_at(TTL), member(user_id, token)) }
    end

    # Shortened rather than removed: the grace tail is what keeps a reload from
    # flapping. Nothing refreshes it afterwards, so it ages out on its own if
    # the user really has gone.
    def disconnect(user_id, token)
      write { redis.zadd(connections_key, expires_at(GRACE), member(user_id, token)) }
    end

    def online?(user_id)
      online_user_ids.include?(user_id.to_s)
    end

    # Every user with at least one connection still counting, in one read. A
    # page intersects this with the rows it is rendering rather than asking per
    # row.
    def online_user_ids
      read(Set.new) do
        redis.zrangebyscore(connections_key, "(#{now}", "+inf")
          .map { |entry| entry.split(":", 2).first }
          .to_set
      end
    end

    # Who changed since the last pass, as `[user_id, online]` pairs. Both the
    # scheduled sweep and the per-user check after a disconnect come through
    # here, so the announced set is the single answer to "what does the world
    # currently believe".
    #
    # `user_ids` narrows the comparison without narrowing the sweep — the
    # after-a-disconnect check has one user to settle and no reason to emit
    # transitions for anybody else.
    def reconcile(user_ids: nil)
      sweep

      live = online_user_ids
      announced = read(Set.new) { redis.smembers(announced_key).to_set }
      candidates = user_ids.nil? ? (live | announced) : Array(user_ids).map(&:to_s).to_set

      candidates.filter_map do |user_id|
        if live.include?(user_id)
          [user_id, true] if announce(user_id)
        elsif announced.include?(user_id)
          [user_id, false] if retract(user_id)
        end
      end
    end

    # Members whose score has passed are already invisible to every read; this
    # only keeps the set from growing without bound.
    def sweep
      write { redis.zremrangebyscore(connections_key, "-inf", now) }
    end

    def reset!
      write { redis.del(connections_key, announced_key) }
    end

    # SADD answers "was it missing", so two sweeps racing emit one transition
    # between them rather than one each.
    private def announce(user_id)
      write(false) { redis.sadd?(announced_key, user_id.to_s) }
    end

    private def retract(user_id)
      write(false) { redis.srem?(announced_key, user_id.to_s) }
    end

    private def member(user_id, token)
      "#{user_id}:#{token}"
    end

    private def now
      Time.current.to_i
    end

    private def expires_at(seconds)
      now + seconds
    end

    # Presence is an enhancement on every path it runs on — a cable connect, a
    # rendered roster — so a Redis that is down costs the dot, never the page.
    private def read(fallback)
      yield
    rescue => e
      Appsignal.report_error(e)
      fallback
    end

    private def write(fallback = nil)
      yield
    rescue => e
      Appsignal.report_error(e)
      fallback
    end

    private def connections_key
      "#{namespace}presence:connections"
    end

    private def announced_key
      "#{namespace}presence:announced"
    end

    # Parallel test workers share one Redis and one cable database, so each one
    # owns its own keys. Same reason as ApiUsageTracker.
    private def namespace
      return "" unless Rails.env.test?

      "test-#{Process.pid}:"
    end

    private def redis
      @redis ||= Redis.new(
        url: Rails.configuration.redis.url,
        db: Rails.configuration.redis.cable_db
      )
    end
  end
end
