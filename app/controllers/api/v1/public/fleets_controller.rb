# frozen_string_literal: true

module Api
  module V1
    module Public
      class FleetsController < ::Api::PublicBaseController
        # The directory scope is the authorization: it holds only fleets that
        # are public, verified and have not opted out.
        skip_verify_authorized only: %i[index]

        before_action :check_fleet_directory_feature, only: %i[index]
        before_action :set_fleet, only: %i[show]

        after_action -> { pagination_header(:fleets) }, only: %i[index]

        rescue_from ActiveRecord::RecordNotFound, ActionPolicy::Unauthorized do |_exception|
          not_found(I18n.t("messages.record_not_found.fleet", slug: params[:slug]))
        end

        DEFAULT_SORTS = ["member_count desc", "name asc"].freeze

        def index
          normalize_sort_params(directory_query_params)
          sorts = sorting_params(Fleet, directory_query_params.delete("sorts"), DEFAULT_SORTS,
            allowed: Fleet::DIRECTORY_SORTING_PARAMS)

          search = directory_query_params.delete(:search)
          directory_query_params[:name_or_fid_or_rsi_verified_sid_cont] = search if search.present?

          activities = directory_query_params.delete(:activity_in)
          directory_query_params[:primary_activity_or_secondary_activity_in] = activities if activities.present?

          @q = Fleet.directory.with_member_count
            .includes(logo_attachment: :blob)
            .ransack(directory_query_params)
          # Many fleets share a member count, and names are not unique either,
          # so without the id last the planner picks their order and paging
          # repeats some and skips others.
          sorts = [*sorts, "name asc"] if sorts.none? { |sort| sort.start_with?("name ") }
          @q.sorts = [*sorts, "id asc"]

          @fleets = @q.result
            .page(page_params)
            .per(per_page(Fleet))
        end

        def show
        end

        private def set_fleet
          @fleet = Fleet.kept.find_by!(slug: params[:slug])

          authorize! @fleet, to: :show?, with: ::Public::FleetPolicy
        end

        private def directory_query_params
          @directory_query_params ||= params.permit(q: [
            :search, :member_count_gteq, :member_count_lteq, :roleplay_eq, :recruiting_eq, :s, :sorts,
            sorts: [], alignment_in: [], activity_in: [], language_in: [], commitment_in: [],
            default_timezone_in: []
          ]).fetch(:q, {})
        end

        private def check_fleet_directory_feature
          return if feature_enabled?("fleet_directory")

          render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
        end
      end
    end
  end
end
