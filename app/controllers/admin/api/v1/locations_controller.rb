# frozen_string_literal: true

module Admin
  module Api
    module V1
      # Every fact is the next load's to replace. The section shows what a load
      # produced -- which records became places, where they nest, what they
      # merged -- and a wrong one is a parser or override fix. Only how a place
      # is drawn, its picture and colour, is edited here.
      class LocationsController < ::Admin::Api::BaseController
        before_action :set_location, only: %i[show update]

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

        def update
          if @location.update(location_params)
            fill_color_from_image

            return render :show
          end

          render json: ValidationError.new("location.update", errors: @location.errors), status: :bad_request
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

        # A planet or moon given a picture and no colour takes its colour from
        # the picture, for the circle it is drawn with. Read off the saved
        # place, not the request: an update that only sends a picture keeps
        # the colour already chosen.
        private def fill_color_from_image
          return if location_params[:image].blank? || @location.color.present?
          return unless %w[planet moon].include?(@location.kind) && @location.image.attached?

          color = ::Locations::ImageColor.new(@location.image.blob).call
          @location.update_column(:color, color) if color
        end

        private def location_params
          params.permit(:image, :color)
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
