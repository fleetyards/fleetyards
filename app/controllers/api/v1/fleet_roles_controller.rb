# frozen_string_literal: true

module Api
  module V1
    class FleetRolesController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.fleet", slug: params[:slug]))
      end

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]

      before_action :set_fleet, only: %i[index]

      def index
        authorize! @fleet, to: :show?, with: FleetPolicy

        @fleet_roles = @fleet.fleet_roles.ranked
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
      end
    end
  end
end
