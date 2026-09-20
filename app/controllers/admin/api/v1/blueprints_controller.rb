# frozen_string_literal: true

module Admin
  module Api
    module V1
      # Read only, and that is the whole design. Every blueprint fact lives on a
      # `BlueprintBuild` that the next load replaces, so anything typed into one
      # would be gone at the next parse -- the section exists to show what a
      # load produced, not to correct it. A wrong recipe is a parser or loader
      # fix.
      class BlueprintsController < ::Admin::Api::BaseController
        # The filters the controller applies itself rather than through
        # ransack. See `source_filters`.
        HAND_APPLIED = %i[from_org consuming_commodity consuming_commodity_in with_known_source with_craftable].freeze

        before_action :set_blueprint, only: %i[show]

        def index
          authorize! with: ::Admin::BlueprintPolicy

          # `normalize_sort_params` first: a sortable list sends `q[s]` and
          # ransack would read a leftover `s` ahead of the whitelisted `sorts`.
          normalize_sort_params(blueprint_query_params)
          blueprint_query_params["sorts"] = sorting_params(Blueprint, blueprint_query_params[:sorts])

          # Both builds, and the cost tree on each: the list reads every fact
          # through `facts`, which is the build we are on *or* the last one
          # that described the recipe, and the default here is the fallback
          # join -- so a retired row renders entirely off `last_build`.
          @q = authorized_scope(Blueprint.with_facts(current_version))
            .includes(
              :craftable,
              build: [:craftable, :sources, {cost_slots: {options: :commodity}}],
              last_build: [:craftable, :sources, {cost_slots: {options: :commodity}}]
            )
            .ransack(blueprint_query_params.except(*HAND_APPLIED))

          @blueprints = source_filters(@q.result)
            .page(params[:page])
            .per(per_page(Blueprint))
        end

        def show
        end

        # The three filter lists the admin selects are built from, each
        # authorized like the resource rather than handed to any signed-in
        # admin.
        def craftable_type_filters
          authorize! with: ::Admin::BlueprintPolicy

          @filters = Blueprint.craftable_type_filters

          render "api/shared/filters"
        end

        def material_filters
          authorize! with: ::Admin::BlueprintPolicy

          # The superset: the admin list defaults to the fallback join, so an
          # option list pinned to the build we are on would omit a material a
          # visible row names. An option that matches nothing costs a click; a
          # missing one cannot be asked for at all.
          @filters = Blueprint.material_filters(current_only: false)

          render "api/shared/filters"
        end

        def org_filters
          authorize! with: ::Admin::BlueprintPolicy

          @filters = Blueprint.org_filters(current_only: false)

          render "api/shared/filters"
        end

        # The four filters that read a build, applied here rather than through
        # ransack, exactly as the public endpoint does.
        #
        # Two reasons, either sufficient. Ransack casts a scope's "false" to a
        # boolean and then skips the scope entirely, so a boolean scope reached
        # through ransack can only ever mean "on" -- `withKnownSource=false`
        # would answer with the whole catalogue rather than the 901 recipes
        # nothing hands out, and `withCraftable=false` would hide the five rows
        # this section exists to surface. And all four have to be told whether
        # the request reads the build we are on or falls back to the last one
        # that described the recipe, which a ransack scope cannot be: it is
        # handed one argument.
        private def source_filters(scope)
          current_only = ActiveModel::Type::Boolean.new.cast(current_version)
          # The *served* build, which is what `with_facts` joins. The configured
          # one is a different build while its load has not finished, and
          # filtering that one while rendering the other answers about a build
          # the response never shows.
          source = Blueprint.served_source

          scope = scope.from_org(org_filter, source, current_only:) if org_filter.present?
          scope = scope.consuming_commodity(commodity_filter, source, current_only:) if commodity_filter.present?

          unless known_source_filter.nil?
            scope = scope.with_known_source(
              ActiveModel::Type::Boolean.new.cast(known_source_filter), source, current_only:
            )
          end

          return scope if craftable_filter.nil?

          scope.with_craftable(
            ActiveModel::Type::Boolean.new.cast(craftable_filter), source, current_only:
          )
        end

        private def org_filter
          blueprint_query_params[:from_org]
        end

        # Both spellings combined: the scalar is what the public filter shipped
        # with and the list is what a multi-select sends, so asking both ways
        # asks for the union rather than for whichever was looked at first.
        private def commodity_filter
          [
            blueprint_query_params[:consuming_commodity],
            *blueprint_query_params[:consuming_commodity_in]
          ].compact.uniq
        end

        private def known_source_filter
          blueprint_query_params[:with_known_source]
        end

        private def craftable_filter
          blueprint_query_params[:with_craftable]
        end

        # Defaulted off, where the public list defaults it on. The admin list
        # has to show a recipe the current build dropped -- "what did this load
        # retire" is one of the questions the section answers -- so the default
        # is the fallback join and `currentVersion=true` narrows to the build
        # we are on.
        private def current_version
          blueprint_query_params.fetch(:current_version, false)
        end

        private def set_blueprint
          @blueprint = Blueprint.includes(
            :craftable,
            build: [:craftable, {cost_slots: [{options: :commodity}, :modifiers]}, :sources],
            last_build: [:craftable, {cost_slots: [{options: :commodity}, :modifiers]}, :sources]
          ).find(params[:id])

          authorize! @blueprint, with: ::Admin::BlueprintPolicy
        end

        private def blueprint_query_params
          @blueprint_query_params ||= params.permit(q: [
            :s, :sorts, :name_cont, :sc_key_cont, :slug_cont, :current_version,
            :craftable_type_eq, :craftable_id_eq,
            :craft_time_lteq, :craft_time_gteq,
            # The four the controller applies itself. Permitted like any other:
            # they are read from here rather than off `params` directly, so an
            # unpermitted one would silently stop filtering.
            :from_org, :with_known_source, :with_craftable,
            :consuming_commodity,
            sorts: [], id_in: [], name_in: [], craftable_type_in: [],
            consuming_commodity_in: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
