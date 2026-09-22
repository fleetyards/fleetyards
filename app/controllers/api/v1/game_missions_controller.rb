# frozen_string_literal: true

module Api
  module V1
    class GameMissionsController < ::Api::PublicBaseController
      include GameMissionFiltersConcern

      skip_verify_authorized only: %i[index show]

      after_action -> { pagination_header(:missions) }, only: [:index]

      # One mission, with what the export is willing to state about it: who
      # offers it, the standing band it is offered in, how hard it is, and what
      # finishing it pays.
      def show
        slug = params[:slug].to_s.downcase

        # `named`, like the list: a page the list will not offer is a page a
        # link should not reach either -- the one predicate D7 is about.
        @mission = GameMission
          .named(GameMission.served_source)
          .includes(build: :rewards, last_build: :rewards)
          .find_by!(slug:)

        # A second query rather than a join: a mission hands out pools, a pool
        # holds up to 48 recipes, and folding that into the row would fan the
        # mission out once per recipe.
        @blueprints = @mission.blueprints.order(:name)
      end

      def index
        # `page_params` rather than `params[:page]`: `?page[]=1` arrives as an
        # Array and `?page[x]=1` as Parameters, and kaminari calls `to_i` on
        # whatever it is handed, which is a 500 for a malformed query string.
        # `Pagination` already guards it -- see its own comment -- and nothing
        # was using the guard.
        @missions = filtered_missions
          .page(page_params)
          .per(per_page(GameMission))
      end
    end
  end
end
