# frozen_string_literal: true

module Api
  module V1
    # The site search over the signed-in user's own hangar.
    class HangarSearchController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?

      def index
        authorize! with: ::HangarPolicy, to: :show?

        @groups = ::HangarSearch.new(
          vehicles: authorized_scope(Vehicle.all).where(hidden: false).purchased
            .where(loaner: false, hidden_by_user: false),
          wishlist: authorized_scope(Vehicle.all).visible.wanted.where(loaner: false),
          friends: current_resource_owner.friends,
          online: method(:online_status_for),
          blueprints: Blueprint.with_facts(true)
            .where(id: current_resource_owner.user_blueprints.select(:blueprint_id)),
          inventory_items: InventoryItem.joins(:inventory).where(inventories: {holder: current_resource_owner}),
          pledge_items: authorized_scope(HangarPledgeItem.all, with: ::HangarPledgeItemPolicy),
          buybacks: authorized_scope(BuybackPledge.all)
        ).call(params[:q])

        render "api/v1/search/index"
      end
    end
  end
end
