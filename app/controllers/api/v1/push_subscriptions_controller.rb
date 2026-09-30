# frozen_string_literal: true

module Api
  module V1
    # The browsers a user subscribed to push notifications.
    #
    # The endpoint never goes back out: a list only needs to say which devices
    # exist, and the browser that created one already knows its own.
    class PushSubscriptionsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "notifications", "notifications:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "notifications", "notifications:write" },
        unless: :user_signed_in?,
        only: %i[create destroy touch]

      before_action :check_push_notifications_feature

      def index
        authorize! with: PushSubscriptionPolicy

        @push_subscriptions = current_resource_owner.push_subscriptions.order(created_at: :desc)
      end

      def create
        authorize! with: PushSubscriptionPolicy

        @push_subscription = PushSubscription.subscribe(
          user: current_resource_owner,
          endpoint: subscription_params[:endpoint],
          p256dh_key: subscription_params.dig(:keys, :p256dh),
          auth_key: subscription_params.dig(:keys, :auth),
          user_agent: request.user_agent
        )

        if @push_subscription.persisted? && @push_subscription.errors.empty?
          render :show, status: @push_subscription.previously_new_record? ? :created : :ok
        else
          render json: ValidationError.new("push_subscription", errors: @push_subscription.errors), status: :bad_request
        end
      end

      # A visit's sign that this browser is still in use, which keeps it out of
      # the prune. It only ever updates an existing row: a device removed in the
      # meantime answers 404 and stays removed, where re-posting the subscription
      # would bring it back. It also leaves the failure count alone, which only a
      # real renewal resets.
      def touch
        @push_subscription = current_resource_owner.push_subscriptions.find(params[:id])

        authorize! @push_subscription

        # False when the row went between the lookup and the update.
        return not_found unless @push_subscription.touch

        render :show
      end

      def destroy
        @push_subscription = current_resource_owner.push_subscriptions.find(params[:id])

        authorize! @push_subscription

        @push_subscription.destroy!

        head :no_content
      end

      # After the doorkeeper callbacks, so a request without a session still
      # gets a 401 rather than a 403 that tells it what exists.
      private def check_push_notifications_feature
        return if Push::Vapid.configured? && feature_enabled?("push_notifications")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end

      private def subscription_params
        params.permit(:endpoint, :expiration_time, keys: %i[p256dh auth])
      end
    end
  end
end
