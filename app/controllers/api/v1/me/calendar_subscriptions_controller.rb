# frozen_string_literal: true

module Api
  module V1
    module Me
      class CalendarSubscriptionsController < ::Api::BaseController
        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "user", "user:read" },
          unless: :user_signed_in?,
          only: %i[show]
        before_action -> { doorkeeper_authorize! "user", "user:write" },
          unless: :user_signed_in?,
          only: %i[create destroy rotate]

        skip_verify_authorized only: %i[show create destroy rotate ics]

        # Personal feed: matches the per-fleet horizon and cancelled retention.
        FEED_PAST_HORIZON = 90.days
        CANCELLED_RETENTION = 7.days

        def show
          @user = current_resource_owner
          render :show
        end

        def create
          @user = current_resource_owner
          @user.ensure_calendar_feed_token!
          render :show
        end

        def rotate
          @user = current_resource_owner
          @user.rotate_calendar_feed_token!
          render :show
        end

        def destroy
          @user = current_resource_owner
          @user.clear_calendar_feed_token!
          head :no_content
        end

        def ics
          token = params[:token].presence || params[:t].presence
          @user = User.find_by(calendar_feed_token: token) if token.present?

          unless @user
            render plain: "Forbidden", status: :forbidden
            return
          end

          now = Time.current
          events = FleetEvent
            .joins(fleet_event_signups: :fleet_membership)
            .where(fleet_memberships: {user_id: @user.id})
            .where(
              fleet_event_signups: {
                status: %w[confirmed pending tentative interested]
              }
            )
            .where(archived_at: nil)
            .where("fleet_events.starts_at >= ?", now - FEED_PAST_HORIZON)
            .where(
              "fleet_events.status != ? OR fleet_events.starts_at >= ?",
              "cancelled",
              now - CANCELLED_RETENTION
            )
            .distinct

          ics = Calendars::IcsBuilder.new(events.to_a,
            calendar_name: "FleetYards — My events",
            organizer_name: "FleetYards").to_ics
          render plain: ics, content_type: "text/calendar; charset=utf-8"
        end
      end
    end
  end
end
