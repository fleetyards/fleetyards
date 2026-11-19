# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FeedbacksController < ::Admin::Api::BaseController
        before_action :set_feedback, only: %i[resolve reopen]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          authorize! with: ::Admin::FeedbackPolicy

          @feedbacks = Feedback.includes(:user, :resolved_by)
            .ransack(feedback_query_params).result
            .order(created_at: :desc)
            .page(page_params)
            .per(per_page(Feedback))
        end

        def resolve
          @feedback.resolved_by = current_admin_user
          transition(:resolve)
        end

        def reopen
          transition(:reopen)
        end

        private def transition(event)
          if @feedback.public_send(event) && @feedback.save
            render :show
          else
            render json: ValidationError.new("feedback.#{event}", errors: @feedback.errors), status: :bad_request
          end
        end

        private def set_feedback
          @feedback = Feedback.find(params[:id])
          authorize! @feedback, with: ::Admin::FeedbackPolicy
        end

        private def feedback_query_params
          params.fetch(:q, {}).permit(:aasm_state_eq, :feature_name_eq, :feature_name_present, :message_cont)
        end
      end
    end
  end
end
