# frozen_string_literal: true

module Api
  module V1
    class CalendarSubscriptionsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create destroy rotate]

      before_action :check_mission_builder_feature
      before_action :set_fleet

      def show
        authorize! @fleet, to: :show?
        render :show
      end

      def create
        authorize! @fleet, to: :manage_calendar?
        @fleet.ensure_calendar_feed_token!
        render :show
      end

      def rotate
        authorize! @fleet, to: :manage_calendar?
        @fleet.rotate_calendar_feed_token!
        render :show
      end

      def destroy
        authorize! @fleet, to: :manage_calendar?
        @fleet.clear_calendar_feed_token!
        head :no_content
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
