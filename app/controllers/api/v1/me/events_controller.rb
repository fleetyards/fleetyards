# frozen_string_literal: true

module Api
  module V1
    module Me
      # The reader's agenda: what is coming up in every fleet they belong to,
      # merged with the events the team curates from the game itself.
      class EventsController < ::Api::BaseController
        include FleetSubscriptionConcern

        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "user", "user:read" },
          unless: :user_signed_in?,
          only: %i[index]

        skip_verify_authorized only: %i[index]

        DEFAULT_WINDOW = 14.days
        MAX_WINDOW = 62.days

        def index
          from = parse_time(params[:from]) || Time.current.beginning_of_day
          to = parse_time(params[:to]) || from + DEFAULT_WINDOW
          to = [to, from + MAX_WINDOW].min

          @items = (fleet_items(from, to) + game_items(from, to)).sort_by { |item| item[:starts_at] }
        end

        private def fleet_items(from, to)
          memberships.flat_map do |membership|
            fleet = membership.fleet
            next [] unless events_available?(fleet)
            next [] unless allowed_to?(:index?, fleet, with: FleetEventPolicy)

            calendar = ::Calendars::FleetEntries.new(
              fleet:,
              membership:,
              from:,
              to:,
              manager: allowed_to?(:manage?, fleet, with: FleetEventPolicy),
              published_only: true
            )

            calendar.entries.map do |entry|
              event, occurrence = entry
              {
                type: "fleet_event",
                starts_at: occurrence || event.starts_at,
                fleet:,
                entry:,
                viewer_signups: calendar.viewer_signups
              }
            end
          end
        end

        # Running events count too, not only those that start in the window: a
        # launch week that began yesterday is still on.
        private def game_items(from, to)
          GameEvent.published.overlapping(from, to).order(:starts_at).map do |game_event|
            {type: "game_event", starts_at: game_event.starts_at, game_event:}
          end
        end

        private def memberships
          current_resource_owner.fleet_memberships.kept.accepted
            .joins(:fleet).merge(Fleet.kept)
            .includes(fleet: {logo_attachment: :blob})
        end

        # The same two gates as the fleet calendar: rolled out for this fleet,
        # and, where enforcement runs, bought.
        private def events_available?(fleet)
          return false unless feature_enabled?("fleet_mission_builder", fleet)

          !(Subscriptions::PREMIUM_FEATURES.include?(:events) && fleet_subscription_missing?(fleet))
        end

        private def parse_time(value)
          return if value.blank?

          Time.zone.parse(value.to_s)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
