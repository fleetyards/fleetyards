# frozen_string_literal: true

module Api
  module V1
    class LocationsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index show]

      after_action -> { pagination_header(:locations) }, only: [:index]

      def index
        normalize_sort_params(locations_query_params)
        locations_query_params["sorts"] = sorting_params(Location, locations_query_params["sorts"])

        @q = Location.current_version(current_version)
          .with_facts(current_version)
          .includes(:parent, build: [], last_build: [])
          .ransack(locations_query_params)

        @locations = @q.result
          .page(page_params)
          .per(per_page(Location))
      end

      # The children are not here: the Nyx star has 464 of them. The list
      # answers them, filtered on `parentIdEq`.
      def show
        @location = Location.current_version(current_version)
          .includes(:map_parent, :terminals, build: [], last_build: [])
          .find_by!(slug: params[:slug].to_s.downcase)

        @ancestors = @location.ancestors.reverse
        @children_count = Location.current_version.where(parent_id: @location.id).count
      end

      private def current_version
        locations_query_params.fetch(:current_version, true)
      end

      private def locations_query_params
        @locations_query_params ||= params.permit(q: [
          :s, :sorts, :name_cont, :current_version,
          :kind_eq, :parent_id_eq, :system_id_eq,
          :shown_on_starmap_eq, :quantum_travel_destination_eq,
          sorts: [], id_in: [], kind_in: [], name_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
