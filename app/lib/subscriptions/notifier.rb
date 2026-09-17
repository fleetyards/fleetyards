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

    def self.ended(subscription)
      new(subscription).ended
    end

    def initialize(subscription)
      @subscription = subscription
    end

    def started
      notify(
        :fleet_subscription_started,
        I18n.t("notifications.fleet_subscription_started.title", fleet: fleet.name)
      )
    end

    # Says what lapsed and why, because "your fleet lost access" without a
    # reason is the message that generates a support ticket rather than
    # answering one.
    def ended
      notify(
        :fleet_subscription_ended,
        I18n.t("notifications.fleet_subscription_ended.title",
          fleet: fleet.name, reason: reason)
      )
    end

    private def reason
      key = @subscription.granted_via_contribution? ? :contribution : :manual

      I18n.t("notifications.fleet_subscription_ended.reasons.#{key}")
    end

    private def notify(type, title)
      admins.each do |admin|
        Notification.notify!(
          user: admin,
          type:,
          title:,
          link: Rails.application.routes.url_helpers.frontend_fleet_path(fleet.slug),
          record: @subscription
        )
      end
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
