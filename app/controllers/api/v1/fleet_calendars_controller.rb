# frozen_string_literal: true

module Api
  module V1
    class FleetCalendarsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]

      before_action :check_mission_builder_feature, only: %i[show]
      before_action :set_fleet, only: %i[show]
      skip_verify_authorized only: %i[ics]

      def show
        authorize! with: FleetEventPolicy, context: {fleet: @fleet}

        from = parse_date(params[:from]) || Time.current.beginning_of_month
        to = parse_date(params[:to]) || from + 35.days

        @events = @fleet.fleet_events
          .where(archived_at: nil)
          .where("starts_at >= ? AND starts_at <= ?", from, to)
          .order(:starts_at)
      end

      # Past horizon: 90 days. Calendar clients don't need the full history
      # and a years-old feed bloats the payload for every poll.
      FEED_PAST_HORIZON = 90.days

      # Cancelled events linger with STATUS:CANCELLED for a week past their
      # start time so subscribed clients see the strike-through, then drop
      # entirely.
      CANCELLED_RETENTION = 7.days

      def ics
        token = params[:token].presence || params[:t].presence
        @fleet = Fleet.find_by!(slug: params[:fleet_slug])

        if @fleet.calendar_feed_token.blank? || token != @fleet.calendar_feed_token
          render plain: "Forbidden", status: :forbidden
          return
        end

        now = Time.current
        events = @fleet.fleet_events
          .where(archived_at: nil)
          .where("starts_at >= ?", now - FEED_PAST_HORIZON)
          .where(
            "status != ? OR starts_at >= ?",
            "cancelled",
            now - CANCELLED_RETENTION
          )
        ics = Calendars::IcsBuilder.new(events.to_a,
          calendar_name: "#{@fleet.name} — Events",
          organizer_name: @fleet.name).to_ics
        render plain: ics, content_type: "text/calendar; charset=utf-8"
      end

      private def parse_date(value)
        return if value.blank?

        Time.zone.parse(value.to_s)
      rescue ArgumentError
        nil
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
