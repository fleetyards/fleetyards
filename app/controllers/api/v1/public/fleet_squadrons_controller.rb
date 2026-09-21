# frozen_string_literal: true

module Api
  module V1
    module Public
      # A fleet's squadrons, as somebody outside it sees them: the names, the
      # colours and how many people are in each. Never who they are -- the
      # roster has its own switch, and a squadron list is the roster grouped.
      class FleetSquadronsController < ::Api::PublicBaseController
        after_action -> { pagination_header(:fleet_squadrons) }, only: %i[index]

        before_action :set_fleet
        before_action :check_fleet_squadrons_feature
        before_action :set_fleet_squadron, only: %i[show]

        rescue_from ActiveRecord::RecordNotFound, ActionPolicy::Unauthorized do |_exception|
          not_found(I18n.t("messages.record_not_found.fleet", slug: params[:fleet_slug]))
        end

        def index
          result = @fleet.fleet_squadrons
            .includes(:fleet_memberships, logo_attachment: :blob)
            .order("name ASC")

          @fleet_squadrons = result_with_pagination(result, per_page(FleetSquadron))
        end

        def show
        end

        private def set_fleet
          @fleet = Fleet.kept.find_by!(slug: params[:fleet_slug])

          authorize! @fleet, to: :show?, with: ::Public::FleetPolicy
        end

        private def set_fleet_squadron
          @fleet_squadron = @fleet.fleet_squadrons.find_by!(slug: params[:slug])
        end

        private def check_fleet_squadrons_feature
          return if feature_enabled?("fleet_squadrons", @fleet)

          not_found(I18n.t("messages.record_not_found.fleet", slug: params[:fleet_slug]))
        end
      end
    end
  end
end
