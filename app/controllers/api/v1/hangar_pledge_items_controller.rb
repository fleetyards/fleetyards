# frozen_string_literal: true

module Api
  module V1
    class HangarPledgeItemsController < ::Api::BaseController
      after_action -> { pagination_header(:hangar_pledge_items) }, only: %i[paints flair equipment upgrades ship_components]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[paints flair equipment upgrades ship_components]

      def upgrades
        list(HangarPledgeItem.upgrades)
      end

      def paints
        list(HangarPledgeItem.paints)
      end

      def flair
        list(HangarPledgeItem.flair)
      end

      def equipment
        list(HangarPledgeItem.equipment)
      end

      def ship_components
        list(HangarPledgeItem.ship_components)
      end

      private def list(scope)
        authorize! with: ::HangarPledgeItemPolicy, to: :index?

        normalize_sort_params(pledge_item_query_params)
        sorts = sorting_params(HangarPledgeItem, pledge_item_query_params.delete("sorts"))

        @q = authorized_scope(scope, with: ::HangarPledgeItemPolicy).ransack(pledge_item_query_params)
        # The hangar order breaks ties within a requested sort, and is the
        # whole order without one.
        @hangar_pledge_items = @q.result
          .includes(:catalogue_component, :catalogue_equipment)
          .order(*HangarPledgeItem.sort_order(sorts), HangarPledgeItem.hangar_order)
          .page(page_params)
          .per(per_page(HangarPledgeItem))

        render :index
      end

      private def pledge_item_query_params
        @pledge_item_query_params ||= params.permit(q: [
          :name_cont, :meltable_eq, :with_value, :upgrade_from_model_slug_eq, :upgrade_to_model_slug_eq, :s, :sorts,
          s: [], sorts: []
        ]).fetch(:q, {})
      end
    end
  end
end
