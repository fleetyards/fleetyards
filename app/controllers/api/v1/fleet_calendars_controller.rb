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

      def ics
        token = params[:token].presence || params[:t].presence
        @fleet = Fleet.find_by!(slug: params[:fleet_slug])

        if @fleet.calendar_feed_token.blank? || token != @fleet.calendar_feed_token
          render plain: "Forbidden", status: :forbidden
          return
        end

        events = @fleet.fleet_events.where(archived_at: nil).where.not(status: "cancelled")
        render plain: build_ics(events), content_type: "text/calendar; charset=utf-8"
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

      private def build_ics(events)
        lines = []
        lines << "BEGIN:VCALENDAR"
        lines << "VERSION:2.0"
        lines << "PRODID:-//Fleetyards//Mission Builder//EN"
        lines << "X-WR-CALNAME:#{ics_escape("#{@fleet.name} — Events")}"

        events.each do |event|
          lines << "BEGIN:VEVENT"
          lines << "UID:#{event.external_uid}@fleetyards.net"
          lines << "DTSTAMP:#{format_ics_time(event.updated_at)}"
          lines << "DTSTART:#{format_ics_time(event.starts_at)}"
          lines << "DTEND:#{format_ics_time(event.ends_at || event.starts_at + 1.hour)}"
          lines << "SUMMARY:#{ics_escape(event.title)}"
          lines << "DESCRIPTION:#{ics_escape(event.description.to_s)}"
          lines << "STATUS:#{ics_event_status(event.status)}"
          lines << "LOCATION:#{ics_escape([event.location, event.meetup_location].compact.join(" — "))}" if event.location.present? || event.meetup_location.present?
          lines << "END:VEVENT"
        end

        lines << "END:VCALENDAR"
        lines.join("\r\n") + "\r\n"
      end

      private def format_ics_time(time)
        time.utc.strftime("%Y%m%dT%H%M%SZ")
      end

      private def ics_event_status(status)
        case status
        when "cancelled" then "CANCELLED"
        when "completed", "active", "locked", "open" then "CONFIRMED"
        else "TENTATIVE"
        end
      end

      private def ics_escape(text)
        text.to_s.gsub(/([,;\\])/, '\\\\\1').gsub("\n", "\\n")
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
