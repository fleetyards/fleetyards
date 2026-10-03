# frozen_string_literal: true

module Api
  module V1
    class LocationsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index show tree contents shops people]

      PEOPLE_LIMIT = 50
      PEOPLE_MAX_LIMIT = 200

      before_action :doorkeeper_authorize!, unless: :user_signed_in?, only: %i[people]

      after_action -> { pagination_header(:locations) }, only: [:index]

      def index
        normalize_sort_params(locations_query_params)
        locations_query_params["sorts"] = sorting_params(Location, locations_query_params["sorts"])

        @q = Location.listed.current_version(current_version)
          .with_facts(current_version)
          .includes({parent: [:parent, :build, :last_build]}, :build, :last_build)
          .ransack(locations_query_params)

        @locations = @q.result
          .page(page_params)
          .per(per_page(Location))
      end

      # The children are not here: the Nyx star has 464 of them. The list
      # answers them, filtered on `parentIdEq`.
      def show
        @location = Location.listed.current_version(current_version)
          .includes({map_parent: [:parent, :build, :last_build]}, {parent: [:parent, :build, :last_build]}, :terminals, :build, :last_build)
          .find_by!(slug: params[:slug].to_s.downcase)

        @ancestors = @location.ancestors.reverse
        @commodities = resource_commodities(@location)
        @children_count = Location.current_version.where(parent_id: @location.id).count
        @places_count = Location.current_version.where(system_id: @location.system_id || @location.id).count
      end

      def tree
        @tree = ::Locations::Tree.new(find_location).call
      end

      def contents
        @groups = ::Locations::Contents.new(find_location).call
      end

      def shops
        @shops = ::Locations::Shops.new(find_location).call
      end

      # Who of the reader's friends and fleet mates is there. Per reader, so not
      # on the place itself, which every reader shares.
      def people
        @people = ::Locations::People.new(
          find_location,
          current_resource_owner,
          friends: feature_enabled?("friends"),
          fleets: doorkeeper_token.blank? || doorkeeper_token.acceptable?(%w[fleet fleet:read]),
          online: ->(user) { online_status_for(user) }
        ).call(limit: people_limit)
      end

      # What a resource name stands for in the commodity catalogue, matched on
      # the name the served build gives it -- the row's own can be older: 41 of
      # the 54 names the 4.10.1 bodies list have one.
      private def resource_commodities(location)
        names = Array.wrap(location.resources).flat_map { |group| Array.wrap(group["items"]).pluck("name") }.compact.map(&:downcase).uniq
        return {} if names.empty?

        Commodity.with_facts(true).where("lower(#{Commodity.fact_sql(:name)}) IN (?)", names).index_by { |commodity| commodity.name.downcase }
      end

      private def people_limit
        return PEOPLE_LIMIT if params[:limit].blank?

        params[:limit].to_i.clamp(1, PEOPLE_MAX_LIMIT)
      end

      private def find_location
        Location.listed.current_version.find_by!(slug: params[:slug].to_s.downcase)
      end

      private def current_version
        locations_query_params.fetch(:current_version, true)
      end

      private def locations_query_params
        @locations_query_params ||= params.permit(q: [
          :s, :sorts, :name_cont, :name_start, :current_version,
          :kind_eq, :parent_id_eq, :system_id_eq,
          :shown_on_starmap_eq, :quantum_travel_destination_eq,
          sorts: [], id_in: [], kind_in: [], name_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
