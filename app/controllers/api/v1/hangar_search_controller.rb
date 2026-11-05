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
          friends: friends_readable? ? current_resource_owner.friends : User.none,
          online: method(:online_status_for),
          blueprints: Blueprint.with_facts(true)
            .where(id: current_resource_owner.user_blueprints.select(:blueprint_id)),
          inventory_items: InventoryItem.joins(:inventory).where(inventories: {holder: current_resource_owner}),
          pledge_items: authorized_scope(HangarPledgeItem.all, with: ::HangarPledgeItemPolicy),
          buybacks: authorized_scope(BuybackPledge.all)
        ).call(params[:q])

        render "api/v1/search/index"
      end

      # A token this endpoint accepts for the hangar need not carry the scopes
      # the friends list asks for.
      private def friends_readable?
        doorkeeper_token.nil? || doorkeeper_token.includes_scope?(*Doorkeeper.config.default_scopes)
      end
    end
  end
end
