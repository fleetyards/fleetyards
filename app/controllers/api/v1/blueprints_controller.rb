# frozen_string_literal: true

module Api
  module V1
    class BlueprintsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index show]

      before_action :check_blueprints_feature

      after_action -> { pagination_header(:blueprints) }, only: [:index]

      # One recipe, with everything a crafter is actually asking: what it makes,
      # what each slot costs, how good the material has to be, and which of that
      # moves which stat.
      def show
        slug = params[:slug].to_s.downcase

        @blueprint = Blueprint.includes(
          :craftable, build: [{cost_slots: [{options: :commodity}, :modifiers]}, :sources]
        ).find_by!(slug:)
      end

      def index
        # `normalize_sort_params` first, because a sortable list sends `q[s]`
        # and ransack would read a leftover `s` ahead of the whitelisted
        # `sorts`.
        normalize_sort_params(blueprints_query_params)
        blueprints_query_params["sorts"] = sorting_params(Blueprint, blueprints_query_params["sorts"])

        # `with_facts` because the filters resolve against the joined build.
        # The same flag ransack gets decides the join: the default is an inner
        # join to the build we are on, and `currentVersion=false` needs the
        # fallback join or a retired recipe would be filtered out before
        # ransack ever saw it.
        @q = Blueprint.with_facts(current_version)
          .includes(:craftable)
          .ransack(blueprints_query_params)

        @blueprints = known_source_scope(@q.result)
          .page(params[:page])
          .per(per_page(Blueprint))
      end

      # Applied here rather than through ransack. Ransack turns a scope's
      # "false" into a boolean and then skips the scope entirely, so asking for
      # the recipes with *no* stated source would quietly return all of them --
      # 1,607 rather than 901. The commodities and equipment endpoints take
      # their version flag off the query for the same reason.
      private def known_source_scope(scope)
        flag = params.dig(:q, :with_known_source)

        return scope if flag.nil?

        scope.with_known_source(ActiveModel::Type::Boolean.new.cast(flag))
      end

      private def current_version
        blueprints_query_params.fetch(:current_version, true)
      end

      private def check_blueprints_feature
        return if feature_enabled?("blueprints")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end

      private def blueprints_query_params
        @blueprints_query_params ||= params.permit(q: [
          :s, :sorts, :name_cont, :current_version,
          :craftable_type_eq, :craftable_id_eq, :from_org, :consuming_commodity,
          :craft_time_lteq, :craft_time_gteq,
          sorts: [], id_in: [], name_in: [], craftable_type_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
