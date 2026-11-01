# frozen_string_literal: true

module Maintenance
  # Takes back the "has lost the fleet features" notices sent while a one-off
  # donation counted only for the calendar month it was paid in.
  #
  # That rule only ever ended a subscription on the 1st of a month, so only
  # notices sent on a 1st are candidates -- read from the notice rather than the
  # row, which an admin may have reopened since. One is wrong when a donation
  # that has not changed since still covered the fleet that day, judged by the rule
  # `SupporterContribution.covering` applies now -- a donation nominated or
  # edited after the closure says nothing about what entitled the fleet then.
  #
  # Each recipient of a wrong notice gets an apology, and a subscription whose
  # fleet is still covered is reopened as the same row: it should never have
  # ended, and a fresh row would send a "features started" notice beside the
  # apology.
  #
  # A dry run writes and sends nothing -- a notification broadcasts the moment
  # it is created, so rolling one back would still show it to an open tab.
  class ApologiseForEarlyFleetSubscriptionEndsTask < MaintenanceTasks::Task
    no_collection

    attribute :dry_run, :boolean, default: true

    def process
      ActiveRecord::Base.with_advisory_lock(::Subscriptions::Sync::LOCK) do
        early_ends.each { |subscription, notices| correct(subscription, notices) }
      end

      log "#{early_ends.size} subscriptions ended early, #{apologies} apologies, #{reopened} reopened"
      log "dry run -- nothing was sent or changed" if dry_run
    end

    private def correct(subscription, notices)
      fleet = subscription.fleet
      reopen = covered?(subscription, Date.current) && !fleet.fleet_subscriptions.open.exists?

      log "#{fleet.name}: told it ended on #{closed_at(notices).to_date}, #{notices.size} notices#{", reopening" if reopen}"

      if reopen
        subscription.update!(ended_at: nil) unless dry_run
        @reopened = reopened + 1
      end

      notices.each { |notice| apologise(notice, subscription) }
    end

    private def apologise(notice, subscription)
      user = notice.user

      I18n.with_locale(user.notification_locale) do
        title = I18n.t("notifications.fleet_subscription_ended_in_error.title", fleet: subscription.fleet.name)
        next if already_apologised?(user, subscription, title)

        @apologies = apologies + 1
        next if dry_run

        ::Notification.notify!(
          user:,
          type: :fleet_subscription_started,
          title:,
          body: I18n.t("notifications.fleet_subscription_ended_in_error.body",
            fleet: subscription.fleet.name,
            date: I18n.l(notice.created_at.to_date, format: :long)),
          link: Rails.application.routes.url_helpers.frontend_fleet_path(subscription.fleet.slug),
          record: subscription
        )
      end
    end

    # Subscription => the ended notices it caused, for every subscription the
    # reconciler closed on a 1st while its fleet was still covered.
    private def early_ends
      @early_ends ||= ::Notification
        .where(notification_type: "fleet_subscription_ended", record_type: "FleetSubscription")
        .where(record_id: FleetSubscription.seeded.select(:id))
        .includes(:user, record: :fleet)
        .select { |notice| notice.created_at.to_date.day == 1 }
        .group_by(&:record)
        .select { |subscription, notices| early?(subscription, notices) }
    end

    private def early?(subscription, notices)
      subscription.present? &&
        covered?(subscription, closed_at(notices).to_date, unchanged_since: closed_at(notices))
    end

    private def closed_at(notices)
      notices.map(&:created_at).min
    end

    private def covered?(subscription, date, unchanged_since: nil)
      scope = SupporterContribution
        .where(fleet_id: subscription.fleet_id)
        .covering(date, grace_days: ::Subscriptions::Sync::GRACE_DAYS)
      scope = scope.where(updated_at: ..unchanged_since) if unchanged_since

      scope.any? { |contribution| ::Subscriptions.qualifying?(contribution) }
    end

    # Matched on the apology's own title rather than on any later "started"
    # notice, which an admin reopening the row by hand also sends.
    private def already_apologised?(user, subscription, title)
      ::Notification.exists?(
        user:,
        notification_type: "fleet_subscription_started",
        record: subscription,
        title:
      )
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
