# frozen_string_literal: true

module Api
  module V1
    class FeedbacksController < ::Api::BaseController
      before_action :set_feedback, only: %i[show reply]

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.base"))
      end

      def index
        authorize! with: FeedbackPolicy

        @feedbacks = authorized_scope(Feedback.all, with: FeedbackPolicy)
          .includes(:replies)
          .order(updated_at: :desc)
          .page(page_params)
          .per(per_page(Feedback))
      end

      def show
      end

      def create
        @feedback = current_user.feedbacks.new(feedback_params)
        authorize! @feedback, with: FeedbackPolicy

        if @feedback.save
          render :show, status: :created
        else
          render json: ValidationError.new("feedbacks.create", errors: @feedback.errors), status: :bad_request
        end
      end

      def reply
        @reply = @feedback.replies.new(body: params[:body])

        if @reply.save
          @feedback.reload
          render :show, status: :created
        else
          render json: ValidationError.new("feedbacks.reply", errors: @reply.errors), status: :bad_request
        end
      end

      private def set_feedback
        @feedback = authorized_scope(Feedback.all, with: FeedbackPolicy).includes(:replies).find(params[:id])
        authorize! @feedback, with: FeedbackPolicy
      end

      private def feedback_params
        params.permit(:message, :feature_name, :page_path)
      end
    end
  end
end
