# frozen_string_literal: true

module Api
  module V1
    class HangarBuybacksController < ::Api::BaseController
      after_action -> { pagination_header(:buyback_pledges) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        only: %i[sync sync_details]

      def index
        authorize! with: ::BuybackPledgePolicy

        @q = authorized_scope(BuybackPledge.all).ransack(buyback_query_params)
        @buyback_pledges = @q.result
          .includes(:upgrade_from_model, :upgrade_to_model)
          .order(reclaimed_on: :desc, name: :asc, id: :asc)
          .page(page_params)
          .per(per_page(BuybackPledge))
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
        @buyback_query_params ||= params.permit(q: [:kind_eq, :name_cont]).fetch(:q, {})
      end

      private def sync_params
        params.permit(items: [
          :id, :kind, :name, :upgraded, :available, :reclaimed_on, :contained, :image,
          :upgrade_from_ship_id, :upgrade_to_ship_id, :upgrade_to_sku_id
        ])
      end

      private def sync_details_params
        params.permit(items: %i[id price currency insurance_months lifetime_insurance])
      end
    end
  end
end
