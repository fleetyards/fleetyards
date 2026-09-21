# frozen_string_literal: true

require "discord/announcement_preview"

module Admin
  module Api
    module V1
      class AnnouncementsController < ::Admin::Api::BaseController
        before_action :set_announcement, only: %i[show update destroy publish send_test retry_delivery]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.announcement"))
        end

        def index
          authorize! with: ::Admin::AnnouncementPolicy

          normalize_sort_params(announcement_query_params)
          announcement_query_params["sorts"] = sorting_params(Announcement, announcement_query_params[:sorts])

          q = Announcement.ransack(announcement_query_params)

          @announcements = q.result(distinct: true)
            .includes(:deliveries, :admin_user)
            .page(params[:page])
            .per(per_page(Announcement))
        end

        def show
        end

        def create
          @announcement = Announcement.new(announcement_params)
          @announcement.admin_user = current_admin_user

          authorize! @announcement, with: ::Admin::AnnouncementPolicy

          return render :show, status: :created if @announcement.save

          render json: ValidationError.new("announcement.create", errors: @announcement.errors), status: :bad_request
        end

        # Content is editable until it goes out and not after: the readers who
        # already have it in their inbox would not see the correction, and the
        # social posts are gone.
        def update
          return render json: ValidationError.new("announcement.already_published"), status: :bad_request unless @announcement.publishable?

          return render :show if @announcement.update(announcement_params)

          render json: ValidationError.new("announcement.update", errors: @announcement.errors), status: :bad_request
        end

        def destroy
          return if @announcement.destroy

          render json: ValidationError.new("announcement.destroy", errors: @announcement.errors), status: :bad_request
        end

        # Sending is a separate action rather than a status the update accepts,
        # so nothing sends an announcement to 57k readers as a side effect of
        # saving a typo fix.
        def publish
          return render json: ValidationError.new("announcement.already_published"), status: :bad_request unless @announcement.publishable?

          ::Announcements::PublishJob.perform_async(@announcement.id)

          render :show
        end

        # The dry run. Goes to the admin Discord channel and nowhere else, and
        # leaves the announcement exactly as it was -- an announcement cannot
        # be recalled, so the one thing worth having beforehand is a look at
        # the real composed output somewhere private.
        def send_test
          return render json: ValidationError.new("announcement.test_not_configured"), status: :bad_request unless ::Discord::AnnouncementPreview.configured?

          ::Announcements::SendTestJob.perform_async(@announcement.id)

          render :show
        end

        def retry_delivery
          delivery = @announcement.deliveries.find_by(channel: params[:channel])

          return not_found(I18n.t("messages.record_not_found.announcement_delivery")) if delivery.blank?

          # Claimed in one statement rather than checked and then written.
          # Posting is not idempotent, so two clicks that each passed a
          # separate status check would put the same announcement on X twice.
          # It also has to be `pending` before the job is queued, or a fast
          # worker writes `succeeded` and this overwrites it.
          return render json: ValidationError.new("announcement.delivery_not_retryable"), status: :bad_request unless delivery.retryable?

          claimed = AnnouncementDelivery
            .where(id: delivery.id, status: delivery.claimable_statuses)
            .update_all(status: "pending", error: nil, updated_at: Time.current)

          return render json: ValidationError.new("announcement.delivery_not_retryable"), status: :bad_request if claimed.zero?

          if delivery.channel_in_app?
            ::Announcements::FanOutJob.perform_async(@announcement.id)
          else
            ::Announcements::PostSocialJob.perform_async(@announcement.id, delivery.channel)
          end

          @announcement.reload

          # The claim is an `update_all` too, so the delivery going back to
          # `pending` reaches the admin who pressed the button in this response
          # and nobody else without this.
          @announcement.broadcast_to_admins

          render :show
        end

        private def set_announcement
          @announcement = Announcement.find(params[:id])

          authorize! @announcement, with: ::Admin::AnnouncementPolicy
        end

        private def announcement_params
          @announcement_params ||= params.permit(
            :title, :body, :link, :icon, :status, :publish_at,
            :notify_users, :post_discord, :post_bluesky, :post_x,
            discord_parts: [], social_parts: []
          ).tap do |permitted|
            # Letting a form set `publishing`, `published` or `failed` would
            # leave an announcement that says it was sent and never was.
            unless ::Admin::V1::Schemas::Enums::AnnouncementInputStatusEnum::AUTHORABLE.include?(permitted[:status])
              permitted.delete(:status)
            end
          end
        end

        private def announcement_query_params
          @announcement_query_params ||= params.permit(q: [
            :search_cont, :title_cont, :status_eq,
            :published_at_gteq, :published_at_lteq,
            :s, :sorts, s: [], sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
