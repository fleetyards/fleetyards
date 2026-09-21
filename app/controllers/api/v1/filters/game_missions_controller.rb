# frozen_string_literal: true

module Api
  module V1
    module Filters
      class GameMissionsController < ::Api::PublicBaseController
        skip_verify_authorized

        # The orgs that actually offer work in the build being read -- 29 of the
        # 38 the export declares reputation records for. A select built from the
        # reputation tree would offer nine options that can only ever come back
        # empty.
        def orgs
          @filters = GameMission.org_filters

          render "api/v1/shared/filters"
        end

        # The standing bands missions are offered in, which is a small subset of
        # the 380 standing records: a band nothing is offered in is not a filter.
        def standings
          @filters = GameMission.standing_filters

          render "api/v1/shared/filters"
        end

        def reward_kinds
          @filters = GameMission.reward_kind_filters

          render "api/v1/shared/filters"
        end
      end
    end
  end
end
