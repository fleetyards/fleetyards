# frozen_string_literal: true

module Maintenance
  # Takes back the "has lost the fleet features" notices sent while a one-off
  # donation counted only for the calendar month it was paid in.
  #
  # A notice was wrong when the donation behind the fleet still covered it on
  # the day the reconciler closed the subscription, judged by the rule
  # `SupporterContribution.covering` applies now. Each recipient of such a
  # notice gets an apology, and a subscription whose fleet is still covered is
  # reopened as the same row -- it should never have ended, and a fresh row
  # would send a "features started" notice beside the apology.
  #
  # Re-runnable: an apology already sent for a subscription is not sent again.
  class ApologiseForEarlyFleetSubscriptionEndsTask < MaintenanceTasks::Task
    no_collection

    attribute :dry_run, :boolean, default: true

    def process
      ActiveRecord::Base.with_advisory_lock(::Subscriptions::Sync::LOCK) do
        ActiveRecord::Base.transaction do
          early_ends.each { |subscription, notices| correct(subscription, notices) }

          log "#{early_ends.size} subscriptions ended early, #{apologies} apologies, #{reopened} reopened"

          if dry_run
            log "dry run -- rolled back, nothing was sent or changed"
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    private def correct(subscription, notices)
      fleet = subscription.fleet
      reopen = covered?(fleet.id, Date.current) && !fleet.fleet_subscriptions.open.exists?

      log "#{fleet.name}: ended #{subscription.ended_at}, #{notices.size} notices#{", reopening" if reopen}"

      if reopen
        subscription.update!(ended_at: nil)
        @reopened = reopened + 1
      end

      notices.each { |notice| apologise(notice, subscription) }
    end

    private def apologise(notice, subscription)
      user = notice.user
      return if already_apologised?(notice, subscription)

      I18n.with_locale(user.notification_locale) do
        ::Notification.notify!(
          user:,
          type: :fleet_subscription_started,
          title: I18n.t("notifications.fleet_subscription_ended_in_error.title", fleet: subscription.fleet.name),
          body: I18n.t("notifications.fleet_subscription_ended_in_error.body",
            fleet: subscription.fleet.name,
            date: I18n.l(notice.created_at.to_date, format: :long)),
          link: Rails.application.routes.url_helpers.frontend_fleet_path(subscription.fleet.slug),
          record: subscription
        )
      end

      @apologies = apologies + 1
    end

    # Subscription => the ended notices it caused, for every subscription the
    # reconciler closed while its fleet was still covered.
    private def early_ends
      @early_ends ||= ::Notification
        .where(notification_type: "fleet_subscription_ended", record_type: "FleetSubscription")
        .includes(:user, record: :fleet)
        .group_by(&:record)
        .select { |subscription, _| early?(subscription) }
    end

    private def early?(subscription)
      subscription.present? &&
        subscription.granted_via_contribution? &&
        subscription.ended_at.present? &&
        covered?(subscription.fleet_id, subscription.ended_at)
    end

    private def covered?(fleet_id, date)
      SupporterContribution
        .where(fleet_id:)
        .covering(date, grace_days: ::Subscriptions::Sync::GRACE_DAYS)
        .any? { |contribution| ::Subscriptions.qualifying?(contribution) }
    end

    # The subscription's own "started" notice predates the wrong one, so only a
    # later notice on the same row is an apology.
    private def already_apologised?(notice, subscription)
      ::Notification
        .where(user: notice.user, notification_type: "fleet_subscription_started", record: subscription)
        .where("created_at > ?", notice.created_at)
        .exists?
    end

    private def apologies
      @apologies ||= 0
    end

    private def reopened
      @reopened ||= 0
    end

    private def log(message)
      puts message
    end
  end
end
