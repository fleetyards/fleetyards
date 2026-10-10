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

          normalize_sort_params(notification_query_params)
          notification_query_params["sorts"] = unread_first(
            sorting_params(AdminNotification, notification_query_params["sorts"])
          )

          @q = scope.ransack(notification_query_params)
          # No distinct: nothing here joins, and SELECT DISTINCT cannot order by
          # the computed `unread` expression.
          @notifications = @q.result
            .page(page_params)
            .per(per_page(AdminNotification))
        end

        def unread_count
          authorize! with: ::Admin::NotificationPolicy

          @unread_count = scope.inbox.unread.count
        end

        def read
          authorize! @notification, with: ::Admin::NotificationPolicy

          @notification.mark_as_read!
          settled([@notification.id])

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
          settled([@notification.id])

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
          unread = scope.inbox.unread
          ids = unread.pluck(:id)
          unread.where(id: ids).update_all(read_at: Time.current, updated_at: Time.current)
          settled(ids)

          head :no_content
        end

        def destroy
          authorize! @notification, with: ::Admin::NotificationPolicy

          @notification.destroy!
          settled([@notification.id])

          head :no_content
        end

        def destroy_all
          authorize! with: ::Admin::NotificationPolicy

          ids = scope.pluck(:id)
          scope.where(id: ids).delete_all
          settled(ids)

          head :no_content
        end

        def read_bulk
          authorize! with: ::Admin::NotificationPolicy

          bulk(:unread, {read_at: Time.current}, settles: true)
        end

        def unread_bulk
          authorize! with: ::Admin::NotificationPolicy

          bulk(:read, {read_at: nil})
        end

        def archive_bulk
          authorize! with: ::Admin::NotificationPolicy

          bulk(:inbox, {archived_at: Time.current}, settles: true)
        end

        def unarchive_bulk
          authorize! with: ::Admin::NotificationPolicy

          bulk(:archived, {archived_at: nil})
        end

        def destroy_bulk
          authorize! with: ::Admin::NotificationPolicy

          ids = bulk_selection.pluck(:id)
          @count = bulk_selection.where(id: ids).delete_all
          settled(ids)

          render :bulk
        end

        # Only the rows the action has something to do to: marking an already read
        # notification read again would move its `read_at` to now for nothing,
        # and the count that comes back is then what actually changed.
        private def bulk(narrow, attributes, settles: false)
          selection = bulk_selection.public_send(narrow)
          ids = selection.pluck(:id)
          @count = selection.where(id: ids).update_all(**attributes, updated_at: Time.current)
          settled(ids) if settles

          render :bulk
        end

        # Plucked before the write, not re-selected after it: a notification
        # that arrives mid-request is not part of what the admin acted on, and
        # its toast has to survive the "all" that missed it.
        private def settled(ids)
          AdminNotification.broadcast_settled(current_admin_user, ids)
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
            :notification_type_eq, :severity_eq, :read_at_null, :archived_at_null, :search_cont, :s, :sorts, s: [], sorts: [], id_in: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
