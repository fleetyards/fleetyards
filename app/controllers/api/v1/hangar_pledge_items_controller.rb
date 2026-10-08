# frozen_string_literal: true

module Api
  module V1
    class HangarPledgeItemsController < ::Api::BaseController
      after_action -> { pagination_header(:hangar_pledge_items) }, only: %i[paints flair]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[paints flair]

      def paints
        list(HangarPledgeItem.paints)
      end

      def flair
        list(HangarPledgeItem.flair)
      end

      private def list(scope)
        authorize! with: ::HangarPledgeItemPolicy, to: :index?

        @q = authorized_scope(scope, with: ::HangarPledgeItemPolicy).ransack(pledge_item_query_params)
        @hangar_pledge_items = @q.result
          .order(HangarPledgeItem.hangar_order)
          .page(page_params)
          .per(per_page(HangarPledgeItem))

        render :index
      end

      private def pledge_item_query_params
        @pledge_item_query_params ||= params.permit(q: [:name_cont, :meltable_eq, :with_value]).fetch(:q, {})
      end
    end
  end
end
