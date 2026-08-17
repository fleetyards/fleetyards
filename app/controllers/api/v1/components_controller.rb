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
            version: Rails.configuration.sc_data[:version]
          )
          .where.not(type_data: nil)
          .where("sc_key IS NULL OR sc_key !~ ?", WEAPON_VARIANT_KEYS)
          .order(name: :asc)
      end

      def index
        components_query_params["sorts"] = "name asc"

        @q = Component.includes(:manufacturer).ransack(components_query_params)

        @components = @q.result
          .page(params[:page])
          .per(per_page(Component))
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
