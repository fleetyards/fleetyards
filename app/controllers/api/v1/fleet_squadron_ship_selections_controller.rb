# frozen_string_literal: true

module Api
  module V1
    # Which of their ships a member gives one squadron. Only ever the reader's
    # own: an officer who wants a particular ship asks for it, and the member
    # answers.
    class FleetSquadronShipSelectionsController < ::Api::BaseController
      include FleetSquadronScoped

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[update]

      before_action :set_fleet
      before_action :check_fleet_squadrons_feature
      before_action :set_fleet_squadron
      before_action :set_row

      def show
      end

      # A list that is supplied is the whole answer to "which ships", so rows
      # not in it go; a list left out leaves the picks alone.
      def update
        attrs = selection_params

        ActiveRecord::Base.transaction do
          @row.assign_attributes(attrs.except(:vehicle_ids))
          @row.hangar_group_id = nil unless @row.ships_filter_hangar_group?
          @row.save!

          sync_vehicles!(attrs[:vehicle_ids]) if attrs.key?(:vehicle_ids)
        end

        @row.fleet_squadron_membership_vehicles.reset

        render :show
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("fleet_squadron_ship_selections.update", errors: e.record.errors), status: :bad_request
      end

      private def sync_vehicles!(ids)
        ids = Array(ids).map(&:to_s).compact_blank.uniq

        @row.fleet_squadron_membership_vehicles.where.not(vehicle_id: ids).destroy_all
        ids.each do |vehicle_id|
          @row.fleet_squadron_membership_vehicles.find_or_create_by!(vehicle_id:)
        end
      end

      private def selection_params
        params.transform_keys(&:underscore).permit(:ships_filter, :hangar_group_id, vehicle_ids: [])
      end

      # Not being in the squadron is a 404: there is no selection to read.
      private def set_row
        membership = @fleet.fleet_memberships.kept.accepted.find_by!(user: current_resource_owner)

        @row = @fleet_squadron.fleet_squadron_memberships
          .includes(:fleet_squadron_membership_vehicles)
          .find_by!(fleet_membership: membership)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end
    end
  end
end
