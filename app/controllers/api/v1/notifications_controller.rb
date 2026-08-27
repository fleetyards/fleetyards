# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < ::Api::BaseController
      after_action -> { pagination_header(:notifications) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "notifications", "notifications:read" },
        unless: :user_signed_in?,
        only: %i[index unread_count]
      before_action -> { doorkeeper_authorize! "notifications", "notifications:write" },
        unless: :user_signed_in?,
        only: %i[read unread archive unarchive read_all destroy destroy_all]

      before_action :set_notification, only: %i[read unread archive unarchive destroy]

      def index
        authorize! with: NotificationPolicy

        notification_query_params["sorts"] = unread_first(
          sorting_params(Notification, notification_query_params["sorts"])
        )

        @q = tab_scope.ransack(notification_query_params.except("archived_at_null"))
        # No distinct: nothing here joins, and SELECT DISTINCT cannot order by
        # the computed `unread` expression.
        @notifications = @q.result
          .page(params[:page])
          .per(per_page(Notification))
      end

      def unread_count
        authorize! with: NotificationPolicy

        @unread_count = scope.pending.unread.count
      end

      def read
        authorize! @notification

        @notification.mark_as_read!

        render :show
      end

      def unread
        authorize! @notification

        @notification.mark_as_unread!

        render :show
      end

      def archive
        authorize! @notification

        @notification.archive!

        render :show
      end

      def unarchive
        authorize! @notification

        @notification.unarchive!

        render :show
      end

      def read_all
        authorize! with: NotificationPolicy

        # The inbox, not the archive: this clears what the unread badge counts,
        # and an archived notification left unread on purpose stays that way.
        scope.pending.unread.update_all(read_at: Time.current, updated_at: Time.current)

        head :no_content
      end

      def destroy
        authorize! @notification

        @notification.destroy!

        head :no_content
      end

      def destroy_all
        authorize! with: NotificationPolicy

        scope.delete_all

        head :no_content
      end

      private def scope
        # No `active` filter: retention archives rather than hides, so an
        # expired notification stays readable under the archive tab until the
        # cleanup job purges it.
        authorized_scope(Notification.all)
      end

      # `archived_at_null` selects a list rather than narrowing one, so it never
      # reaches ransack: a notification past its retention belongs in the
      # archive whether or not the nightly job has written that down yet, and
      # `archived_at IS NULL` alone would leave it in the inbox until then.
      private def tab_scope
        archive = notification_query_params["archived_at_null"].to_s == "false"

        archive ? scope.filed : scope.pending
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
          :notification_type_eq, :read_at_null, :archived_at_null, :search_cont, :sorts, sorts: []
        ]).fetch(:q, {})
      end
    end
  end
end
