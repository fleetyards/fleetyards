# frozen_string_literal: true

module Api
  module V1
    class BlueprintsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index show]

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
        # The three build-reading filters are taken off the query: ransack
        # would either skip them or apply them against the wrong build.
        # The build and its cost tree come along: a row names the materials it
        # consumes, and without this the list pays three queries per row for
        # them.
        @q = Blueprint.with_facts(current_version)
          .includes(:craftable, build: {cost_slots: {options: :commodity}})
          .ransack(blueprints_query_params.except(:from_org, :consuming_commodity, :with_known_source))

        @blueprints = source_filters(@q.result)
          .page(params[:page])
          .per(per_page(Blueprint))
      end

      # The three filters that read a build, applied here rather than through
      # ransack.
      #
      # Two reasons, and each one alone is enough. Ransack turns a scope's
      # "false" into a boolean and then skips the scope entirely, so
      # `withKnownSource=false` would quietly return the whole catalogue --
      # 1,607 rather than 901. And all three have to know whether the request
      # is reading the build we are on or falling back to the last one that
      # described the recipe, which a ransack scope cannot be told: it is
      # handed one argument.
      #
      # Filtering the current build while rendering the fallback is the bug
      # this shape exists to avoid -- it drops a retired recipe whose retained
      # build does name the org being asked for, and lets one through
      # `withKnownSource=false` whose own response says a source is known.
      private def source_filters(scope)
        current_only = current_version
        source = ::ScData::Source.current

        scope = scope.from_org(org_filter, source, current_only:) if org_filter.present?
        scope = scope.consuming_commodity(commodity_filter, source, current_only:) if commodity_filter.present?

        return scope if known_source_filter.nil?

        scope.with_known_source(
          ActiveModel::Type::Boolean.new.cast(known_source_filter), source, current_only:
        )
      end

      private def org_filter
        blueprints_query_params[:from_org]
      end

      private def commodity_filter
        blueprints_query_params[:consuming_commodity]
      end

      private def known_source_filter
        blueprints_query_params[:with_known_source]
      end

      private def current_version
        blueprints_query_params.fetch(:current_version, true)
      end

      private def blueprints_query_params
        @blueprints_query_params ||= params.permit(q: [
          :s, :sorts, :name_cont, :current_version,
          :craftable_type_eq, :craftable_id_eq,
          # The three the controller applies itself. Permitted like any other:
          # they are read from here rather than off `params` directly, so an
          # unpermitted one would silently stop filtering.
          :from_org, :with_known_source,
          :craft_time_lteq, :craft_time_gteq,
          sorts: [], id_in: [], name_in: [], craftable_type_in: [],
          consuming_commodity: []
        ]).fetch(:q, {})
      end
    end
  end
end
