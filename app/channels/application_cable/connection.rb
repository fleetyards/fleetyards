# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :current_admin_user

    # This connection's own handle in the presence set. Presence is per
    # connection rather than per user, and the handle is minted here rather
    # than taken from the client: nothing the browser sends can be trusted to
    # name a connection it does not own.
    attr_reader :presence_token

    def connect
      self.current_user = find_verified_user
      self.current_admin_user = find_verified_admin_user

      @presence_token = SecureRandom.uuid

      start_presence
    end

    # Only fires on a graceful close. A killed worker, a replaced container, a
    # laptop lid — none of them run this, which is why the connection's score
    # expires on its own rather than waiting to be removed.
    def disconnect
      stop_presence
    end

    protected def find_verified_user
      env["warden"].user(:user)
    end

    protected def find_verified_admin_user
      env["warden"].user(:admin_user)
    end

    # Announced from here rather than from a reconcile pass, because green has
    # to arrive within seconds of the app opening. The fan-out itself goes to
    # Sidekiq: it reads every fleet and friendship the user holds, and the cable
    # thread is the wrong place for that.
    private def start_presence
      return if current_user.blank?
      return unless UserPresence.connect(current_user.id, presence_token)

      begin
        ::Presence::BroadcastTransitionJob.perform_async(current_user.id, true)
      rescue
        # The announcement is already committed, so nothing would emit this
        # again. Putting it back leaves it to the next sweep.
        UserPresence.revert(current_user.id, true)
        raise
      end
    rescue => e
      Appsignal.report_error(e)
    end

    # The connection is scored down to its grace tail rather than removed, so a
    # reload — a disconnect followed by a connect a second later — never leaves
    # a gap for anybody to see. The check runs once that tail has run out.
    private def stop_presence
      return if current_user.blank?

      UserPresence.disconnect(current_user.id, presence_token)

      ::Presence::OfflineCheckJob.perform_in(UserPresence::GRACE + 5, current_user.id)
    rescue => e
      Appsignal.report_error(e)
    end
  end
end
