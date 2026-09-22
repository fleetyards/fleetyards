# frozen_string_literal: true

module Admin
  module Api
    module V1
      # Read only, and that is the whole design. Every mission fact lives on a
      # `GameMissionBuild` that the next load replaces, so anything typed into
      # one would be gone at the next parse -- the section exists to show what
      # a load produced, not to correct it. A wrong title is a parser fix.
      class GameMissionsController < ::Admin::Api::BaseController
        # The filters the controller applies itself rather than through
        # ransack. See `build_filters`.
        HAND_APPLIED = %i[released rewarding rewarding_in from_org named].freeze

        before_action :set_mission, only: %i[show]

        def index
          authorize! with: ::Admin::GameMissionPolicy

          # `normalize_sort_params` first: a sortable list sends `q[s]` and
          # ransack would read a leftover `s` ahead of the whitelisted `sorts`.
          normalize_sort_params(mission_query_params)
          mission_query_params["sorts"] = sorting_params(GameMission, mission_query_params[:sorts])

          # Both builds: the list reads every fact through `facts`, which is the
          # build we are on *or* the last one that described the mission, and
          # the default here is the fallback join -- so a retired row renders
          # entirely off `last_build`.
          @q = authorized_scope(GameMission.with_facts(current_version))
            .includes(build: :rewards, last_build: :rewards)
            .ransack(mission_query_params.except(*HAND_APPLIED))

          @missions = build_filters(@q.result)
            .page(page_params)
            .per(per_page(GameMission))
        end

        def show
        end

        def org_filters
          authorize! with: ::Admin::GameMissionPolicy

          # The superset: the admin list defaults to the fallback join, so an
          # option list pinned to the build we are on would omit an org a
          # visible row names. An option that matches nothing costs a click; a
          # missing one cannot be asked for at all.
          @filters = GameMission.org_filters(GameMission.served_source, current_only: false)

          render "api/shared/filters"
        end

        def standing_filters
          authorize! with: ::Admin::GameMissionPolicy

          @filters = GameMission.standing_filters(GameMission.served_source, current_only: false)

          render "api/shared/filters"
        end

        def reward_kind_filters
          authorize! with: ::Admin::GameMissionPolicy

          @filters = GameMission.reward_kind_filters

          render "api/shared/filters"
        end

        # The filters that read a build, applied here rather than through
        # ransack, exactly as the public endpoint does: ransack casts a scope's
        # "false" to a boolean and then skips the scope, so `released=false`
        # would answer with the whole catalogue rather than the 349 the build
        # is not offering -- and none of them can be told whether the request
        # reads the build we are on or falls back.
        private def build_filters(scope)
          current_only = ActiveModel::Type::Boolean.new.cast(current_version)
          source = GameMission.served_source

          scope = scope.from_org(org_filter, source, current_only:) if org_filter.present?
          scope = scope.rewarding(reward_filter, source, current_only:) if reward_filter.present?

          # The 74 contracts the game never named. The public catalogue excludes
          # them outright; here they are a filter, because "what did this load
          # bring in that nobody can read" is a question this section exists to
          # answer.
          unless named_filter.nil?
            scope = if ActiveModel::Type::Boolean.new.cast(named_filter)
              scope.named(source, current_only:)
            else
              scope.where.not(id: GameMission.named(source, current_only:).select(:id))
            end
          end

          return scope if released_filter.nil?

          return scope.released(source, current_only:) if ActiveModel::Type::Boolean.new.cast(released_filter)

          scope.where.not(id: GameMission.released(source, current_only:).select(:id))
        end

        private def org_filter
          mission_query_params[:from_org]
        end

        private def reward_filter
          [
            mission_query_params[:rewarding],
            *mission_query_params[:rewarding_in]
          ].compact.uniq
        end

        private def released_filter
          mission_query_params[:released]
        end

        private def named_filter
          mission_query_params[:named]
        end

        # Defaulted off, where the public list defaults it on. The admin list
        # has to show a mission the current build dropped -- "what did this load
        # retire" is one of the questions the section answers.
        private def current_version
          mission_query_params.fetch(:current_version, false)
        end

        private def set_mission
          @mission = GameMission
            .includes(build: :rewards, last_build: :rewards)
            .find(params[:id])

          authorize! @mission, with: ::Admin::GameMissionPolicy
        end

        private def mission_query_params
          @mission_query_params ||= params.permit(q: [
            :s, :sorts, :name_cont, :sc_key_cont, :slug_cont, :debug_name_cont,
            :current_version, :kind_eq, :alignment_eq, :org_name_eq,
            :min_standing_eq, :generator_key_eq,
            # The ones the controller applies itself. Permitted like any other:
            # they are read from here rather than off `params` directly, so an
            # unpermitted one would silently stop filtering.
            :released, :named, :rewarding, :from_org,
            sorts: [], id_in: [], name_in: [], kind_in: [], alignment_in: [],
            org_name_in: [], min_standing_in: [], rewarding_in: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
