# frozen_string_literal: true

module Admin
  module Api
    module V1
      class NotificationsController < ::Admin::Api::BaseController
        after_action -> { pagination_header(:notifications) }, only: %i[index]

        before_action :set_notification, only: %i[read destroy]

        def index
          authorize! with: ::Admin::NotificationPolicy

          notification_query_params["sorts"] = unread_first(
            sorting_params(AdminNotification, notification_query_params["sorts"])
          )

          @q = scope.ransack(notification_query_params)
          # No distinct: nothing here joins, and SELECT DISTINCT cannot order by
          # the computed `unread` expression.
          @notifications = @q.result
            .page(params[:page])
            .per(per_page(AdminNotification))
        end

        def unread_count
          authorize! with: ::Admin::NotificationPolicy

          @unread_count = scope.unread.count
        end

        def read
          authorize! @notification, with: ::Admin::NotificationPolicy

          @notification.mark_as_read!

          render :show
        end

        def read_all
          authorize! with: ::Admin::NotificationPolicy

          scope.unread.update_all(read_at: Time.current, updated_at: Time.current)

          head :no_content
        end

        def destroy
          authorize! @notification, with: ::Admin::NotificationPolicy

          @notification.destroy!

          head :no_content
        end

        def destroy_all
          authorize! with: ::Admin::NotificationPolicy

          scope.delete_all

          head :no_content
        end

        private def scope
          authorized_scope(AdminNotification.all, with: ::Admin::NotificationPolicy).active
        end

        private def set_notification
          @notification = scope.find(params[:id])
        end

        # The requested sort only orders within the unread and read groups.
        private def unread_first(sorts)
          ["unread desc", *Array(sorts)]
        end

        private def notification_query_params
          @notification_query_params ||= params.permit(q: [
            :notification_type_eq, :severity_eq, :read_at_null, :search_cont, :sorts, sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
