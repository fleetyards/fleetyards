# frozen_string_literal: true

module Subscriptions
  # Tells a fleet's admins that its entitlement changed (D14).
  #
  # Losing four capabilities silently is the worst version of this, so the
  # notification has to land before anybody meets a refusal -- which means it is
  # sent where the subscription is written, not where it is read.
  #
  # One place rather than a callback on the model: the reconciler and the admin
  # surface both write subscriptions, and only some of those writes are events
  # worth telling anybody about. An `after_save` would have to re-derive which,
  # and would fire on a backfill or a fixture too.
  class Notifier
    def self.started(subscription)
      new(subscription).started
    end

    def self.ended(subscription, cause:)
      new(subscription).ended(cause:)
    end

    # What changed, given what the row looked like before the write.
    #
    # Two states matter and they are not the same. `open?` is whether the row
    # has an end date; `active_on?` is whether it grants *today*. A grant dated
    # into the future is open but grants nothing, and one ending today is
    # closed but still grants -- so a rule built on either alone gets one of
    # them wrong.
    def self.announce(subscription, was_open:, was_active:, cause:)
      notifier = new(subscription)
      is_open = subscription.persisted? && subscription.open?
      is_active = subscription.persisted? && subscription.active_on?

      # Ending a grant is news whether it stops today or at a date named now.
      return notifier.ended(cause:) if (was_open && !is_open) || (was_active && !is_active)

      notifier.started if !was_active && is_active
    end

    def initialize(subscription)
      @subscription = subscription
    end

    def started
      notify(:fleet_subscription_started) do
        I18n.t("notifications.fleet_subscription_started.title", fleet: fleet.name)
      end
    end

    # Says what lapsed and why, because "your fleet lost access" without a
    # reason is the message that generates a support ticket rather than
    # answering one.
    #
    # The cause is passed rather than derived from `granted_via`: an admin can
    # close a contribution-backed subscription while its donation is still
    # active, and saying the donation lapsed would then be false.
    def ended(cause:)
      notify(:fleet_subscription_ended) do
        I18n.t("notifications.fleet_subscription_ended.title",
          fleet: fleet.name,
          reason: I18n.t("notifications.fleet_subscription_ended.reasons.#{cause}"))
      end
    end

    # The title is persisted, so it is translated once per recipient in their
    # own locale rather than once in whatever language the job happened to run
    # in -- the fleet's admins do not have to share one.
    private def notify(type)
      admins.each do |admin|
        I18n.with_locale(locale_for(admin)) do
          Notification.notify!(
            user: admin,
            type:,
            title: yield,
            link: Rails.application.routes.url_helpers.frontend_fleet_path(fleet.slug),
            record: @subscription.persisted? ? @subscription : nil
          )
        end
      end
    end

    # `users.locale` already holds one of the app's own locales, so this only
    # has to survive a blank or a stale one -- I18n raises on an unavailable
    # locale rather than falling back.
    private def locale_for(user)
      stored = user.locale.presence
      return I18n.default_locale if stored.blank?

      I18n.available_locales.map(&:to_s).include?(stored) ? stored.to_sym : I18n.default_locale
    end

    private def fleet
      @fleet ||= @subscription.fleet
    end

    # The people who could do something about it. A member cannot change what
    # the fleet is entitled to, so telling all 400 of them is noise -- and
    # `fleet:manage` is the privilege that already means "runs this fleet".
    private def admins
      fleet.fleet_memberships.kept.accepted.includes(:fleet_role, :user)
        .select { |membership| membership.has_access?(["fleet:manage"]) }
        .filter_map(&:user)
    end
  end
end
