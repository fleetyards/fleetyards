# frozen_string_literal: true

module Admin
  module Api
    module V1
      class NotificationsController < ::Admin::Api::BaseController
        after_action -> { pagination_header(:notifications) }, only: %i[index]

        before_action :set_notification, only: %i[read unread archive unarchive destroy]

        def index
          authorize! with: ::Admin::NotificationPolicy

          notification_query_params["archived_at_null"] = true unless notification_query_params.key?("archived_at_null")

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

          @unread_count = scope.inbox.unread.count
        end

        def read
          authorize! @notification, with: ::Admin::NotificationPolicy

          @notification.mark_as_read!

          render :show
        end

        def unread
          authorize! @notification, with: ::Admin::NotificationPolicy

          @notification.mark_as_unread!

          render :show
        end

        def archive
          authorize! @notification, with: ::Admin::NotificationPolicy

          @notification.archive!

          render :show
        end

        def unarchive
          authorize! @notification, with: ::Admin::NotificationPolicy

          @notification.unarchive!

          render :show
        end

        def read_all
          authorize! with: ::Admin::NotificationPolicy

          # The inbox, not the archive: this clears what the unread badge counts,
          # and an archived notification left unread on purpose stays that way.
          scope.inbox.unread.update_all(read_at: Time.current, updated_at: Time.current)

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

        def read_bulk
          authorize! with: ::Admin::NotificationPolicy

          bulk(:unread, read_at: Time.current)
        end

        def unread_bulk
          authorize! with: ::Admin::NotificationPolicy

          bulk(:read, read_at: nil)
        end

        def archive_bulk
          authorize! with: ::Admin::NotificationPolicy

          bulk(:inbox, archived_at: Time.current)
        end

        def unarchive_bulk
          authorize! with: ::Admin::NotificationPolicy

          bulk(:archived, archived_at: nil)
        end

        def destroy_bulk
          authorize! with: ::Admin::NotificationPolicy

          @count = bulk_selection.delete_all

          render :bulk
        end

        # Only the rows the action has something to do to: marking an already read
        # notification read again would move its `read_at` to now for nothing,
        # and the count that comes back is then what actually changed.
        private def bulk(narrow, attributes)
          @count = bulk_selection.public_send(narrow)
            .update_all(**attributes, updated_at: Time.current)

          render :bulk
        end

        # The reader either ticked rows or asked for everything the current
        # filter matches, and `all` has to say so out loud. A body naming
        # neither selects nothing rather than everything: the other reading of
        # it is `destroy_all` by accident.
        private def bulk_selection
          return filtered_scope if ActiveModel::Type::Boolean.new.cast(params[:all])

          scope.where(id: Array(params[:ids]))
        end

        # The list the index would return, without the paging and without the
        # ordering - PostgreSQL refuses an ORDER BY in an UPDATE, and it means
        # nothing there anyway.
        private def filtered_scope
          query = notification_query_params.except("sorts")
          query["archived_at_null"] = true unless query.key?("archived_at_null")

          scope.ransack(query).result.reorder(nil)
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
            :notification_type_eq, :severity_eq, :read_at_null, :archived_at_null, :search_cont, :sorts, sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
