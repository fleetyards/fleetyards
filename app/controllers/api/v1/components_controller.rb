# frozen_string_literal: true

module Api
  module V1
    class ComponentsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index weapons]

      after_action -> { pagination_header(:components) }, only: [:index]

      # Variants of a gun that exist only inside the game files — level-of-detail
      # meshes, NPC security-network copies, turret-only and ship-bespoke builds,
      # and cosmetic skin editions that are statistically identical to their
      # base weapon. None are loadout options, and including them inflated the
      # list to 175 against the 133 erkul shows.
      WEAPON_VARIANT_KEYS = [
        "_lowpoly", "_collector", "_securitynetwork", "_bespoke", "_weak", "_shark",
        "_turret", "automatedturret",
        "_idris", "_javelin", "_bengal", "_vng_"
      ].join("|").freeze

      # Slim, unpaginated list of every ship gun in the current game version,
      # carrying only what the deflection check needs. The full component
      # serializer (prices, media, hardpoints) is far too heavy for ~200 rows.
      def weapons
        @weapons = Component
          .includes(:manufacturer)
          .where(
            category: "weapons",
            component_sub_type: "Gun",
            version: ::ScData::Source.version
          )
          .where.not(type_data: nil)
          .where("sc_key IS NULL OR sc_key !~ ?", WEAPON_VARIANT_KEYS)
          .order(name: :asc)
      end

      def index
        components_query_params["sorts"] = "name asc"

        # `with_facts` because the filters resolve against the joined build.
        # Without it a fact condition raises rather than quietly matching the
        # column, which is the failure mode to want.
        #
        # The same flag ransack gets decides the join: for the default it is an
        # inner join to the build we are on, which already leaves out everything
        # that build does not describe. `currentVersion=false` needs the fallback
        # join, or a retired component would be filtered out by the join before
        # ransack ever sees it.
        @q = Component.with_facts(current_version)
          .includes(:manufacturer)
          .ransack(components_query_params)

        @components = @q.result
          .page(params[:page])
          .per(per_page(Component))
      end

      # Read rather than removed from the query: `current_version` stays a
      # ransackable scope, so ransack applies it as well. The exists check it adds
      # is redundant beside the inner join and free beside the fallback one.
      private def current_version
        components_query_params.fetch(:current_version, true)
      end

      private def components_query_params
        @components_query_params ||= params.permit(q: [
          :name_cont, :current_version, :hidden_eq,
          id_in: [], name_in: [], item_type_in: [], manufacturer_slug_in: [], component_class_in: [],
          category_in: [], component_sub_type_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
