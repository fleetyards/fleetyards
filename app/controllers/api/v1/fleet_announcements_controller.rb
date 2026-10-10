# frozen_string_literal: true

module Api
  module V1
    class FleetAnnouncementsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy]

      before_action :set_fleet
      before_action :set_fleet_announcement, only: %i[update destroy]

      # Only what is still standing: an expired announcement has said its piece.
      def index
        authorize! with: FleetAnnouncementPolicy, context: {fleet: @fleet}

        @fleet_announcements = @fleet.fleet_announcements.active
          .includes(author: {avatar_attachment: :blob})
          .order(created_at: :desc)
      end

      def create
        @fleet_announcement = @fleet.fleet_announcements.new(fleet_announcement_params)
        @fleet_announcement.author = current_resource_owner

        authorize! @fleet_announcement, context: {fleet: @fleet}

        if @fleet_announcement.save
          ActiveSupport::Notifications.instrument("fleet_announcement.posted", announcement: @fleet_announcement)

          render :show, status: :created
        else
          render json: ValidationError.new("fleet_announcements.create", errors: @fleet_announcement.errors),
            status: :bad_request
        end
      end

      def update
        authorize! @fleet_announcement, context: {fleet: @fleet}

        if @fleet_announcement.update(fleet_announcement_params)
          render :show
        else
          render json: ValidationError.new("fleet_announcements.update", errors: @fleet_announcement.errors),
            status: :bad_request
        end
      end

      def destroy
        authorize! @fleet_announcement, context: {fleet: @fleet}

        return if @fleet_announcement.destroy

        render json: ValidationError.new("fleet_announcements.destroy", errors: @fleet_announcement.errors),
          status: :bad_request
      end

      private def fleet_announcement_params
        authorized(params, with: FleetAnnouncementPolicy)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end

      private def set_fleet_announcement
        @fleet_announcement = @fleet.fleet_announcements.find(params[:id])
      end
    end
  end
end
