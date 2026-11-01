# frozen_string_literal: true

module Maintenance
  # Takes back the "has lost the fleet features" notices sent while a one-off
  # donation counted only for the calendar month it was paid in.
  #
  # A notice is wrong when a donation that has not changed since still covered
  # the fleet on the day it was sent -- read from the notice rather than the
  # row, which an admin may have reopened since -- by the rule
  # `SupporterContribution.covering` applies now. A donation nominated or
  # edited after the closure says nothing about what entitled the fleet then,
  # and that is also what keeps out a closure caused by a nomination being
  # withdrawn.
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
        early_ends.each { |(subscription, _day), notices| correct(subscription, notices) }
      end

      log "#{early_ends.size} early closures, #{apologies} apologies, #{reopened} reopened"
      log "dry run -- nothing was sent or changed" if dry_run
    end

    private def correct(subscription, notices)
      fleet = subscription.fleet
      reopen = covered?(subscription, Date.current) &&
        !fleet.fleet_subscriptions.open.exists? &&
        reopened_ids.add?(subscription.id)

      log "#{fleet.name}: told it ended on #{closed_at(notices).to_date}, #{notices.size} notices#{", reopening" if reopen}"

      if reopen
        subscription.update!(ended_at: nil) unless dry_run
      end

      notices.each { |notice| apologise(notice, subscription) }
    end

    private def apologise(notice, subscription)
      user = notice.user

      I18n.with_locale(user.notification_locale) do
        title = I18n.t("notifications.fleet_subscription_ended_in_error.title", fleet: subscription.fleet.name)
        next if already_apologised?(user, subscription)
        next unless apologised.add?([user.id, subscription.id])
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

    # [subscription, day] => the ended notices sent that day, for every closure
    # the reconciler made while the fleet was still covered. Judged per day, so
    # a genuine lapse later in the same row's life is not excused along with an
    # early one.
    #
    # Only notices giving the lapsed donation as the reason: an administrator
    # ending a grant says so in its title, and that decision is not undone here.
    # The title is the only record of the cause, persisted in the recipient's
    # locale, so every locale's wording is tried.
    private def early_ends
      @early_ends ||= ::Notification
        .where(notification_type: "fleet_subscription_ended", record_type: "FleetSubscription")
        .where(record_id: FleetSubscription.seeded.select(:id))
        .includes(:user, record: :fleet)
        .select { |notice| lapsed_donation?(notice) }
        .group_by { |notice| [notice.record, notice.created_at.to_date] }
        .select { |(subscription, day), notices| early?(subscription, day, notices) }
    end

    private def lapsed_donation?(notice)
      lapsed_donation_reasons.any? { |reason| notice.title.include?(reason) }
    end

    private def lapsed_donation_reasons
      @lapsed_donation_reasons ||= I18n.available_locales.map do |locale|
        I18n.t("notifications.fleet_subscription_ended.reasons.contribution", locale:)
      end.uniq
    end

    private def early?(subscription, day, notices)
      subscription.present? && covered?(subscription, day, unchanged_since: closed_at(notices))
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
    # notice, which an admin reopening the row by hand also sends -- in every
    # locale, since the recipient may have switched language since the last run.
    private def already_apologised?(user, subscription)
      titles = I18n.available_locales.map do |locale|
        I18n.t("notifications.fleet_subscription_ended_in_error.title", fleet: subscription.fleet.name, locale:)
      end

      ::Notification.exists?(
        user:,
        notification_type: "fleet_subscription_started",
        record: subscription,
        title: titles
      )
    end

    private def apologised
      @apologised ||= Set.new
    end

    private def apologies
      apologised.size
    end

    private def reopened_ids
      @reopened_ids ||= Set.new
    end

    private def reopened
      reopened_ids.size
    end

    private def log(message)
      puts message
    end
  end
end
