# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < ::Api::BaseController
      after_action -> { pagination_header(:notifications) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "notifications", "notifications:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "notifications", "notifications:write" },
        unless: :user_signed_in?,
        only: %i[read read_all destroy destroy_all]

      before_action :set_notification, only: %i[read destroy]

      def index
        authorize! with: NotificationPolicy

        scope = authorized_scope(Notification.all).active

        notification_query_params["sorts"] = sorting_params(Notification, notification_query_params["sorts"])

        @q = scope.ransack(notification_query_params)
        @notifications = @q.result(distinct: true)
          .order(created_at: :desc)
          .page(params[:page])
          .per(per_page(Notification))
      end

      def read
        authorize! @notification

        @notification.mark_as_read!
      end

      def read_all
        authorize! with: NotificationPolicy

        authorized_scope(Notification.all).unread.update_all(read_at: Time.current)

        head :no_content
      end

      def destroy
        authorize! @notification

        @notification.destroy!
      end

      def destroy_all
        authorize! with: NotificationPolicy

        authorized_scope(Notification.all).delete_all

        head :no_content
      end

      private def set_notification
        @notification = authorized_scope(Notification.all).find(params[:id])
      end

      private def notification_query_params
        @notification_query_params ||= params.permit(q: [
          :notification_type_eq, :read_at_null, :sorts, sorts: []
        ]).fetch(:q, {})
      end
    end
  end
end
