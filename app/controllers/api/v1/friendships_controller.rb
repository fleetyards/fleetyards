# frozen_string_literal: true

module Api
  module V1
    # A user's friends, and the requests in both directions.
    #
    # Addressed by the other user's username throughout, which is the only
    # handle on a friendship anybody outside the API has.
    class FriendshipsController < ::Api::BaseController
      include RelationshipActions
      include RelationshipsFeatureConcern

      before_action :authenticate_user!, only: []
      before_action :doorkeeper_authorize!, unless: :user_signed_in?, only: %i[index show pending_count]
      before_action -> { doorkeeper_authorize! "profile:write" },
        unless: :user_signed_in?,
        only: %i[create destroy accept decline ignore]

      before_action :check_friends_feature
      before_action :set_relationship, only: %i[show destroy accept decline ignore]

      after_action -> { pagination_header(:friends) }, only: %i[index]

      # Requests waiting on this user, for the badge that says so. `awaiting`
      # rather than the listing scope: a row the reader ignored is no longer
      # waiting on them, and a count that included it would be a badge they
      # could never clear.
      def pending_count
        authorize! ::Friendship, to: :index?, with: ::FriendshipPolicy

        @pending_count = ::Friendship.outstanding_for(current_resource_owner)
      end

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.friendship"))
      end

      private def relation_class = ::Friendship

      private def relationship_policy = ::FriendshipPolicy

      private def acting_party = current_resource_owner

      # `username` on the member routes and in the create body alike.
      private def requested_party
        ::User.find_by!(normalized_username: params[:username].to_s.downcase)
      end
    end
  end
end
