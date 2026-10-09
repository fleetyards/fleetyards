# frozen_string_literal: true

module Api
  module V1
    class HangarBuybacksController < ::Api::BaseController
      after_action -> { pagination_header(:buyback_pledges) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index insurance_terms]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[sync sync_details]

      def index
        authorize! with: ::BuybackPledgePolicy

        normalize_sort_params(buyback_query_params)
        sorts = sorting_params(BuybackPledge, buyback_query_params.delete("sorts"))

        @q = authorized_scope(BuybackPledge.all).ransack(buyback_query_params)
        sorts = [*sorts, "name asc"] if sorts.none? { |sort| sort.start_with?("name ") }
        @q.sorts = sorts

        # Many pledges share a reclaim date, a price and a name, so without the
        # id last the planner picks their order and paging repeats some and
        # skips others. Ordered outside ransack, which drops a sort on an
        # attribute it may not search.
        @buyback_pledges = @q.result
          .order(:id)
          .includes(:upgrade_from_model, :upgrade_to_model)
          .page(page_params)
          .per(per_page(BuybackPledge))
      end

      # The terms the caller's pledges carry, so the filter offers only those.
      def insurance_terms
        authorize! with: ::BuybackPledgePolicy

        @insurance_terms = authorized_scope(BuybackPledge.all).insurance_terms
      end

      # An empty list is a valid answer -- every pledge was bought back -- but
      # anything that is not a list is refused rather than read as one: the
      # sync deletes whatever the list leaves out.
      def sync
        authorize! with: ::BuybackPledgePolicy

        unless params[:items].is_a?(Array)
          render json: ValidationError.new("buyback_pledges.sync", message: I18n.t("messages.hangar_sync.no_data")), status: :bad_request
          return
        end

        render json: ::BuybackPledges::Sync.new(current_resource_owner, sync_params.fetch(:items, [])).run
      rescue ::BuybackPledges::Sync::InvalidSnapshot
        render json: ValidationError.new("buyback_pledges.sync"), status: :bad_request
      end

      def sync_details
        authorize! with: ::BuybackPledgePolicy

        unless params[:items].is_a?(Array)
          render json: ValidationError.new("buyback_pledges.sync_details", message: I18n.t("messages.hangar_sync.no_data")), status: :bad_request
          return
        end

        render json: ::BuybackPledges::StoreDetails.new(current_resource_owner, sync_details_params.fetch(:items, [])).run
      end

      private def buyback_query_params
        @buyback_query_params ||= params.permit(q: [
          :kind_eq, :name_cont, :price_gteq, :price_lteq,
          :upgrade_from_model_slug_eq, :upgrade_to_model_slug_eq, :s, :sorts,
          price_in: [], insurance_in: [], s: [], sorts: []
        ]).fetch(:q, {})
      end

      private def sync_params
        params.permit(items: [
          :id, :kind, :name, :upgraded, :available, :reclaimed_on, :contained, :image,
          :upgrade_from_ship_id, :upgrade_to_ship_id, :upgrade_to_sku_id
        ])
      end

      private def sync_details_params
        params.permit(items: %i[id price insurance_months lifetime_insurance])
      end
    end
  end
end
