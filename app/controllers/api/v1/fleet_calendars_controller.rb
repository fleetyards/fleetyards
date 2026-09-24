# frozen_string_literal: true

module Api
  module V1
    class FleetCalendarsController < ::Api::BaseController
      include FleetSubscriptionConcern
      include SquadronVisibilityConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]

      before_action :set_fleet, only: %i[show]
      before_action :check_fleet_mission_builder_feature, only: %i[show]
      before_action -> { require_fleet_subscription(:events) }, only: %i[show]
      skip_verify_authorized only: %i[ics]

      def show
        authorize! with: FleetEventPolicy, context: {fleet: @fleet}

        from = parse_date(params[:from]) || Time.current.beginning_of_month
        to = parse_date(params[:to]) || from + 35.days

        one_off = @fleet.fleet_events
          .where(archived_at: nil, recurring: false)
          .where("starts_at >= ? AND starts_at <= ?", from, to)

        recurring = @fleet.fleet_events
          .where(archived_at: nil, recurring: true)
          .where("starts_at <= ?", to)

        # The same events the list shows this reader, and no more.
        unless allowed_to?(:manage?, @fleet, with: FleetEventPolicy)
          one_off = narrow_to_squadron_access(one_off)
          recurring = narrow_to_squadron_access(recurring)
        end

        entries = one_off.map { |e| [e, nil] }
        recurring.each do |event|
          event.occurrences(from: from, to: to).each do |occurrence|
            entries << [event, occurrence]
          end
        end

        @calendar_entries = entries.sort_by { |(event, occurrence)| occurrence || event.starts_at }
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

        # Both gates, in order. Checked here rather than in a
        # callback because the fleet is resolved from the path inside this
        # action, and answered in plain text because a calendar client is what
        # reads it.
        #
        # The capability first: a feature that is not rolled out is unavailable
        # to everyone, and checking only the subscription would have served a
        # subscribed fleet a feed the flag says does not exist. Then the
        # entitlement, or a token already issued would keep serving the whole
        # feed after the fleet lapsed.
        unless feature_enabled?("fleet_mission_builder", @fleet)
          render plain: "Forbidden", status: :forbidden
          return
        end

        if fleet_subscription_missing?(@fleet)
          render plain: "Forbidden", status: :forbidden
          return
        end

        # The token is the fleet's, not a reader's, so there is nobody to ask
        # which squadrons may see what: an event held to squadrons stays out.
        now = Time.current
        events = @fleet.fleet_events
          .not_squadron_restricted
          .includes(:fleet_event_occurrence_states)
          .where(archived_at: nil)
          .starting_after(now - FEED_PAST_HORIZON)
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

      private def check_fleet_mission_builder_feature
        return if feature_enabled?("fleet_mission_builder", @fleet)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
