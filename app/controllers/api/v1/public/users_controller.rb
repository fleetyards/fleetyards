# frozen_string_literal: true

module Api
  module V1
    module Public
      class UsersController < ::Api::PublicBaseController
        include HangarShareTokenConcern

        before_action :set_user

        def show
          @show_presence = presence_visible?
        end

        # Whether somebody is around is for the people who might go and find
        # them: their friends and fleet mates, not whoever opens their card.
        private def presence_visible?
          reader = current_resource_owner
          return false if reader.blank? || reader.id == @user.id
          return true if reader.friend_of?(@user)

          ::FleetMembership.kept.accepted
            .where(user_id: @user.id, fleet_id: reader.fleet_memberships.kept.accepted.select(:fleet_id))
            .exists?
        end

        private def set_user
          @user = User.find_by!(normalized_username: params[:username].downcase)

          authorize! @user, with: ::Public::UserPolicy
        end
      end
    end
  end
end
