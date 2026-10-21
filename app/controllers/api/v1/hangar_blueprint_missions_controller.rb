# frozen_string_literal: true

module Api
  module V1
    # The missions worth running for the reader's wishlist: every mission whose
    # reward pools hold a blueprint they want, and which of those it can hand
    # out. Generated from the wishlist alone -- nothing is stored per mission.
    class HangarBlueprintMissionsController < ::Api::BaseController
      include GameMissionFiltersConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?

      after_action -> { pagination_header(:missions) }, only: %i[index]

      def index
        authorize! with: ::HangarPolicy

        pools = wanted_pools
        source = GameMission.served_source

        scope = GameMission.named(source, current_only: current_version)
          .dropping_pool(pools.keys, source, current_only: current_version)

        @missions = filtered_missions(scope)
          .page(page_params)
          .per(per_page(GameMission))

        @wanted_blueprints = wanted_blueprints_for(@missions, pools)
      end

      # Each pool the reader's wanted blueprints drop from, with the blueprints
      # in it. Through the build we are on, the way `GameMission#blueprints`
      # resolves the same link from the other end.
      private def wanted_pools
        BlueprintSource
          .joins(:build)
          .merge(BlueprintBuild.current)
          .where(blueprint_builds: {
            blueprint_id: UserBlueprint.wanted.where(user_id: current_resource_owner.id).select(:blueprint_id)
          })
          .pluck(:pool_sc_ref, "blueprint_builds.blueprint_id")
          .each_with_object(Hash.new { |hash, key| hash[key] = Set.new }) do |(pool, blueprint_id), pools|
            pools[pool] << blueprint_id
          end
      end

      # Which wanted blueprints each mission on the page can hand out, keyed by
      # mission. One query for the blueprints of the whole page.
      private def wanted_blueprints_for(missions, pools)
        ids_by_mission = missions.to_h do |mission|
          refs = mission.blueprint_pool_refs || []

          [mission.id, refs.flat_map { |ref| pools.fetch(ref, []).to_a }.uniq]
        end

        # The builds come along because a blueprint's name reads through them.
        blueprints = Blueprint.includes(:build, :last_build)
          .where(id: ids_by_mission.values.flatten.uniq)
          .index_by(&:id)

        ids_by_mission.transform_values do |ids|
          blueprints.values_at(*ids).compact.sort_by { |blueprint| blueprint.name.to_s }
        end
      end
    end
  end
end
