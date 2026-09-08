# frozen_string_literal: true

require "sidekiq/api"

module Admin
  module Api
    module V1
      # One request for the whole landing page.
      #
      # The figures here come from six different tables, and every one of them
      # used to be either a separate request or not shown at all. They are
      # assembled together because the page reads them together -- ten tiles
      # must not become ten round trips.
      class DashboardController < ::Admin::Api::BaseController
        include TrackingStatsConcern

        # A failure from last year is history, not a to-do. The dashboard asks
        # what needs attention now; /imports/ holds the rest.
        RECENT_FAILURE_WINDOW = 24.hours

        # Only the traffic figures are cached. The attention tiles above them --
        # failed imports, stuck imports, unlisted models -- are cheap counts on
        # indexed columns, and they are the ones an admin is watching for.
        TRAFFIC_TTL = 5.minutes

        def show
          authorize! with: ::Admin::DashboardPolicy

          @dashboard = {}

          add_models_figures
          add_import_figures
          add_rsi_figures
          add_notification_figures
          add_worker_figures
          add_traffic_figures
        end

        private def add_models_figures
          return unless current_user.has_access?([:models])

          @dashboard[:unlisted_models_count] = ScDataUnlistedModel.undecided.count

          last_load = Import.where(type: "Imports::ScData::AllImport", aasm_state: "finished")
            .where.not(version: nil)
            .order(finished_at: :desc)
            .first

          @dashboard[:catalogue_version] = last_load&.version
          @dashboard[:catalogue_loaded_at] = last_load&.finished_at
        end

        private def add_import_figures
          return unless current_user.has_access?([:imports])

          @dashboard[:failed_imports_count] =
            Import.where(aasm_state: "failed", failed_at: RECENT_FAILURE_WINDOW.ago..).count

          @dashboard[:stuck_imports_count] = Import.stuck.count
        end

        private def add_rsi_figures
          return unless current_user.has_access?([:"rsi-api-status"])

          @dashboard[:unresolved_rsi_request_logs_count] = RsiRequestLog.where(resolved: false).count
        end

        private def add_notification_figures
          # No privilege gate: the notification scope is already this admin's own
          # inbox, narrowed to the types their privileges make them a recipient of.
          @dashboard[:actionable_notifications_count] =
            authorized_scope(AdminNotification.all, with: ::Admin::NotificationPolicy)
              .active.inbox.unread
              .where(severity: %w[warning error])
              .count
        end

        # Queue health, which until now meant leaving for the Sidekiq web UI to
        # find out. A retry backlog is the one number here that grows quietly:
        # nothing fails loudly, the jobs just keep being rescheduled.
        private def add_worker_figures
          return unless current_user.has_access?([:workers])

          stats = Sidekiq::Stats.new

          @dashboard[:jobs_enqueued_count] = stats.enqueued
          @dashboard[:jobs_retry_count] = stats.retry_size
          @dashboard[:jobs_dead_count] = stats.dead_size
        rescue => e
          # Redis being unreachable is worth knowing about, but not by taking the
          # whole dashboard down with it -- every other figure comes from Postgres.
          Rails.logger.warn("dashboard: sidekiq stats unavailable: #{e.message}")
        end

        private def add_traffic_figures
          return unless current_user.has_access?([:stats])

          @dashboard[:online_count] = online_count

          # The page polls every thirty seconds and these four scan `ahoy_visits`
          # and `users` for a window measured in days. The date is in the key so
          # they roll over at midnight rather than at whatever the entry's five
          # minutes happen to be.
          @dashboard.merge!(
            Rails.cache.fetch("admin/dashboard/traffic/#{Time.zone.today}", expires_in: TRAFFIC_TTL) do
              traffic_figures
            end
          )
        end

        private def traffic_figures
          today = Time.zone.today

          {
            visits_today: visits_on(today),
            # The same weekday, not yesterday: traffic has a weekly shape, and a
            # Monday compared against a Sunday reads as a spike every week.
            visits_same_weekday_last_week: visits_on(today - 1.week),
            signups_this_week: User.where(created_at: today.beginning_of_week..).count,
            signups_last_week: User.where(
              created_at: (today - 1.week).beginning_of_week...today.beginning_of_week
            ).count
          }
        end

        private def visits_on(date)
          Ahoy::Visit.without_users(tracking_blocklist)
            .where(started_at: date.beginning_of_day..date.end_of_day)
            .count
        end
      end
    end
  end
end
