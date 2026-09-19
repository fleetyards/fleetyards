# frozen_string_literal: true

module Api
  module V1
    class BlueprintsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index show]

      # The catalogue is public; saying you hold a recipe is not. Guarded the
      # way every mixed controller here is -- a session passes straight
      # through, and anything else has to carry a token with the scope.
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[own unown]

      after_action -> { pagination_header(:blueprints) }, only: [:index]

      # One recipe, with everything a crafter is actually asking: what it makes,
      # what each slot costs, how good the material has to be, and which of that
      # moves which stat.
      def show
        slug = params[:slug].to_s.downcase

        @blueprint = Blueprint.includes(
          :craftable, build: [{cost_slots: [{options: :commodity}, :modifiers]}, :sources]
        ).find_by!(slug:)

        @owned_blueprint_ids = owned_ids_for([@blueprint])
      end

      # Idempotent on purpose: holding a recipe is a state, not an event, so
      # marking one twice is the same answer rather than a duplicate row or a
      # validation error a client has to interpret.
      def own
        blueprint = Blueprint.find_by!(slug: params[:slug].to_s.downcase)

        authorize! blueprint

        UserBlueprint.find_or_create_by!(user_id: current_resource_owner.id, blueprint_id: blueprint.id)

        head :no_content
      rescue ActiveRecord::RecordNotUnique
        # Two clicks landing together. The row exists either way, which is what
        # was asked for.
        head :no_content
      end

      def unown
        blueprint = Blueprint.find_by!(slug: params[:slug].to_s.downcase)

        authorize! blueprint, to: :unown?

        UserBlueprint.where(user_id: current_resource_owner.id, blueprint_id: blueprint.id).destroy_all

        head :no_content
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
          .ransack(blueprints_query_params.except(:from_org, :consuming_commodity, :with_known_source, :owned))

        @blueprints = owned_filter(source_filters(@q.result))
          .page(params[:page])
          .per(per_page(Blueprint))

        # One query for the page rather than one per row, and after pagination
        # so it asks about the 60 rows being rendered rather than the 1,607.
        @owned_blueprint_ids = owned_ids_for(@blueprints)
      end

      # Applied here rather than through ransack for the reason
      # `with_known_source` is: ransack casts a scope argument to a boolean and
      # then skips the scope when it is false, so `owned=false` would answer
      # "the recipes I do not have" with the whole catalogue.
      private def owned_filter(scope)
        flag = blueprints_query_params[:owned]

        return scope if flag.nil?

        # Off the resolved owner rather than off a parameter: whose recipes are
        # being asked about is never the caller's to name.
        holder = current_resource_owner

        if ActiveModel::Type::Boolean.new.cast(flag)
          scope.owned_by(holder)
        else
          scope.not_owned_by(holder)
        end
      end

      # The subset of these blueprints the reader holds. Empty when signed out,
      # which is what the payload's `owned: false` says.
      private def owned_ids_for(blueprints)
        holder = current_resource_owner

        return Set.new if holder.blank?

        Set.new(
          UserBlueprint.where(user_id: holder.id, blueprint_id: blueprints.map(&:id)).pluck(:blueprint_id)
        )
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
        # The *served* build, which is what `with_facts` joins. The configured
        # one is a different build while its load has not finished, and
        # filtering that one while rendering the other answers about a build
        # the response never shows.
        source = Blueprint.served_source

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

      # Both spellings, combined: the scalar is what the filter shipped with and
      # the list is what a multi-select sends, and asking both ways asks for
      # the union rather than for whichever the controller looked at first.
      private def commodity_filter
        [
          blueprints_query_params[:consuming_commodity],
          *blueprints_query_params[:consuming_commodity_in]
        ].compact.uniq
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
          :from_org, :with_known_source, :owned,
          :craft_time_lteq, :craft_time_gteq,
          :consuming_commodity,
          sorts: [], id_in: [], name_in: [], craftable_type_in: [],
          consuming_commodity_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
