# frozen_string_literal: true

module Admin
  module Api
    module V1
      # Read only: every fact is the next load's to replace. The section shows
      # what a load produced -- which records became places, where they nest,
      # what they merged -- and a wrong one is a parser or override fix.
      class LocationsController < ::Admin::Api::BaseController
        before_action :set_location, only: %i[show]

        def index
          authorize! with: ::Admin::LocationPolicy

          normalize_sort_params(location_query_params)
          location_query_params["sorts"] = sorting_params(Location, location_query_params[:sorts])

          @q = authorized_scope(Location.with_facts(current_version))
            .includes({parent: [:parent, :build, :last_build]}, :build, :last_build)
            .ransack(location_query_params)

          @locations = @q.result
            .page(page_params)
            .per(per_page(Location))
        end

        def show
        end

        # Defaulted off, where the public list defaults it on: what a load
        # retired is one of the questions this section answers.
        private def current_version
          location_query_params.fetch(:current_version, false)
        end

        private def set_location
          @location = Location
            .includes({parent: [:parent, :build, :last_build]}, {map_parent: [:parent, :build, :last_build]}, :system, :terminals, :build, :last_build)
            .find(params[:id])

          authorize! @location, with: ::Admin::LocationPolicy
        end

        private def location_query_params
          @location_query_params ||= params.permit(q: [
            :s, :sorts, :name_cont, :sc_key_cont, :slug_cont, :current_version,
            :kind_eq, :parent_id_eq, :system_id_eq, :shown_on_starmap_eq,
            sorts: [], id_in: [], kind_in: [], name_in: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
