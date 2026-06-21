# frozen_string_literal: true

require "discord/scheduled_event_sync"

module Api
  module V1
    class FleetEventsController < ::Api::BaseController
      after_action -> { pagination_header(:fleet_events) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show ics]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy unarchive sync_to_discord publish lock_signups unlock_signups start complete cancel skip_occurrence end_series update_occurrence]

      before_action :check_mission_builder_feature
      before_action :set_fleet
      before_action :set_event, only: %i[show update destroy unarchive sync_to_discord publish lock_signups unlock_signups start complete cancel ics skip_occurrence end_series update_occurrence]
      before_action :set_mission, only: %i[create]

      def index
        authorize! with: FleetEventPolicy, context: {fleet: @fleet}

        scope = if params[:archived] == "true"
          @fleet.fleet_events.where.not(archived_at: nil)
        else
          @fleet.fleet_events.where(archived_at: nil)
        end
        scope = (params[:upcoming] == "true") ? scope.upcoming : scope
        scope = scope.past if params[:past] == "true"

        query_params = params.fetch(:q, {}).permit(:title_cont, :status_eq, :category_eq, :s)
        normalize_sort_params(query_params)

        @q = scope.ransack(query_params)
        result = @q.result(distinct: true)

        @fleet_events = result_with_pagination(result, 30)
      end

      def show
        authorize! @fleet_event

        @viewer_event_role = compute_viewer_event_role(@fleet_event)
        @occurrence_date = parsed_show_occurrence_date
        @occurrence_state =
          if @occurrence_date
            @fleet_event.occurrence_state_for(@occurrence_date)
          end
      end

      private def parsed_show_occurrence_date
        raw = params[:occurrence_date].presence || params[:occurrence].presence
        return nil if raw.blank?
        Date.parse(raw.to_s)
      rescue ArgumentError, TypeError
        nil
      end

      def create
        @fleet_event = if @mission
          FleetEvent.from_mission!(@mission, event_params.merge(created_by: current_resource_owner))
        else
          @fleet.fleet_events.new(event_params.merge(created_by: current_resource_owner))
        end

        authorize! @fleet_event

        if @mission || @fleet_event.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_events.create", errors: @fleet_event.errors), status: :bad_request
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("fleet_events.create", errors: e.record.errors), status: :bad_request
      end

      def update
        authorize! @fleet_event

        if @fleet_event.update(event_params)
          render :show
        else
          render json: ValidationError.new("fleet_events.update", errors: @fleet_event.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @fleet_event

        if @fleet_event.archived?
          if @fleet_event.destroy
            ActiveSupport::Notifications.instrument("fleet_event.destroyed", event: @fleet_event)
          else
            render json: ValidationError.new("fleet_events.destroy", errors: @fleet_event.errors), status: :bad_request
          end
        elsif @fleet_event.archive!
          ActiveSupport::Notifications.instrument("fleet_event.archived", event: @fleet_event)
          render :show
        else
          render json: ValidationError.new("fleet_events.destroy", errors: @fleet_event.errors), status: :bad_request
        end
      end

      def skip_occurrence
        authorize! @fleet_event, to: :update?

        unless @fleet_event.recurring?
          render json: {code: "not_recurring", message: "Event is not recurring"}, status: :unprocessable_entity
          return
        end

        date = params[:date].presence || params.dig(:occurrence_date)
        if date.blank?
          render json: {code: "missing_date", message: "date is required"}, status: :bad_request
          return
        end

        parsed = Date.parse(date.to_s)
        @fleet_event.skip_occurrence!(parsed)

        # If this occurrence was previously pushed to Discord, drop the
        # scheduled event there so members don't see an orphan.
        state = @fleet_event.occurrence_state_for(parsed)
        if state&.discord_event_id.present?
          begin
            ::Discord::ScheduledEventSync.new(@fleet_event, occurrence_date: parsed).delete!
          rescue ::Discord::ApiClient::Error => e
            Rails.logger.warn("[discord-sync] could not clean up scheduled event after skip: #{e.message}")
          end
        end

        render :show
      end

      # Update an individual occurrence of a recurring event. Override
      # columns on the per-occurrence state row (title, description,
      # location, etc) leave the parent event unchanged. Pass nil to clear
      # a previously-set override and fall back to the event's value.
      def update_occurrence
        authorize! @fleet_event, to: :update?

        unless @fleet_event.recurring?
          render json: {code: "not_recurring", message: "Event is not recurring"}, status: :unprocessable_entity
          return
        end

        date = params[:date].presence
        if date.blank?
          render json: {code: "missing_date", message: "date is required"}, status: :bad_request
          return
        end

        parsed = Date.parse(date.to_s)
        state = @fleet_event.occurrence_state_for(parsed, build: true)

        attrs = params.permit(
          :title, :description, :briefing,
          :location, :meetup_location, :scenario, :cover_image_preset
        ).to_h
        state.assign_attributes(attrs)

        if state.save
          @occurrence_state = state
          render :occurrence_state
        else
          render json: ValidationError.new("fleet_events.update_occurrence", errors: state.errors), status: :bad_request
        end
      end

      def end_series
        authorize! @fleet_event, to: :update?

        unless @fleet_event.recurring?
          render json: {code: "not_recurring", message: "Event is not recurring"}, status: :unprocessable_entity
          return
        end

        date = params[:date].presence
        if date.blank?
          render json: {code: "missing_date", message: "date is required"}, status: :bad_request
          return
        end

        @fleet_event.end_series_at!(date)
        render :show
      end

      def unarchive
        authorize! @fleet_event, to: :unarchive?

        unless @fleet_event.archived?
          render json: {code: "invalid_state", message: "Event is not archived"}, status: :bad_request
          return
        end

        @fleet_event.unarchive!
        ActiveSupport::Notifications.instrument("fleet_event.unarchived", event: @fleet_event)
        render :show
      end

      def ics
        authorize! @fleet_event, to: :show?

        ics = Calendars::IcsBuilder.new([@fleet_event],
          calendar_name: @fleet_event.title,
          organizer_name: @fleet.name).to_ics
        send_data ics,
          type: "text/calendar; charset=utf-8",
          disposition: %(attachment; filename="#{@fleet_event.slug}.ics")
      end

      # Manually push the event to Discord. Useful for events that were
      # already published before the fleet connected its Discord server,
      # since publish-time notifications already fired and won't be replayed.
      DISCORD_SYNC_OCCURRENCE_COUNT = 4

      def sync_to_discord
        authorize! @fleet_event, to: :update?

        sync = ::Discord::ScheduledEventSync.new(@fleet_event)
        unless sync.runnable?
          render json: {code: "discord_not_configured", message: "Discord isn't configured for this fleet"}, status: :unprocessable_entity
          return
        end

        if @fleet_event.recurring?
          occurrences = @fleet_event
            .occurrences(from: Time.current, to: 16.weeks.from_now)
            .first(DISCORD_SYNC_OCCURRENCE_COUNT)

          occurrences.each do |occurrence|
            ::Discord::ScheduledEventSync.new(
              @fleet_event,
              occurrence_date: occurrence.to_date
            ).upsert!
          end
        else
          sync.upsert!
        end

        render :show
      rescue ::Discord::ApiClient::Error => e
        render json: {code: "discord_error", message: e.message, status: e.status}, status: :bad_gateway
      end

      %i[publish lock_signups unlock_signups start complete].each do |action|
        define_method(action) do
          authorize! @fleet_event, to: :"#{action}?"
          if @fleet_event.send("may_#{action}?")
            @fleet_event.send("#{action}!")
            ActiveSupport::Notifications.instrument("fleet_event.#{transition_name(action)}", event: @fleet_event)
            render :show
          else
            render json: {code: "invalid_state", message: "Cannot #{action} from #{@fleet_event.status}"}, status: :bad_request
          end
        end
      end

      def cancel
        authorize! @fleet_event, to: :cancel?
        if @fleet_event.may_cancel?
          @fleet_event.update(cancelled_reason: params[:cancelled_reason]) if params[:cancelled_reason].present?
          @fleet_event.cancel!
          ActiveSupport::Notifications.instrument("fleet_event.cancelled", event: @fleet_event)
          render :show
        else
          render json: {code: "invalid_state", message: "Cannot cancel from #{@fleet_event.status}"}, status: :bad_request
        end
      end

      private def transition_name(action)
        case action
        when :publish then "published"
        when :lock_signups then "locked"
        when :unlock_signups then "unlocked"
        when :start then "started"
        when :complete then "completed"
        else action.to_s
        end
      end

      private def event_params
        authorized(params, with: FleetEventPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end

      private def set_event
        @fleet_event = @fleet.fleet_events.find_by!(slug: params[:slug])
      end

      private def set_mission
        return if params[:mission_slug].blank?

        @mission = @fleet.missions.find_by!(slug: params[:mission_slug])
      end

      private def compute_viewer_event_role(event)
        viewer = current_resource_owner
        return nil unless viewer

        return "creator" if event.created_by_id == viewer.id
        event.event_admin_role_for(viewer)
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
