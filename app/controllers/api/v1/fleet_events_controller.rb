# frozen_string_literal: true

module Api
  module V1
    class FleetEventsController < ::Api::BaseController
      after_action -> { pagination_header(:fleet_events) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy publish lock_signups unlock_signups start complete cancel]

      before_action :check_mission_builder_feature
      before_action :set_fleet
      before_action :set_event, only: %i[show update destroy unarchive publish lock_signups unlock_signups start complete cancel]
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
