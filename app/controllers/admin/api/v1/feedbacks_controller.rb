# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FeedbacksController < ::Admin::Api::BaseController
        before_action :set_feedback, only: %i[show resolve reopen reply]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          authorize! with: ::Admin::FeedbackPolicy

          @feedbacks = Feedback.includes(:user, :resolved_by, :replies)
            .ransack(feedback_query_params).result
            .order(created_at: :desc)
            .page(page_params)
            .per(per_page(Feedback))
        end

        def show
        end

        def resolve
          transition(:resolve) { @feedback.resolved_by = current_admin_user }
        end

        def reopen
          transition(:reopen)
        end

        def reply
          @reply = @feedback.replies.new(body: params[:body], from_admin: true, admin_user: current_admin_user)

          if @reply.save
            @feedback.reload
            render :show, status: :created
          else
            render json: ValidationError.new("feedback.reply", errors: @reply.errors), status: :bad_request
          end
        end

        # Under the lock, so two admins acting at once do not both pass the
        # state check and leave the second one's name on it.
        private def transition(event)
          done = @feedback.with_lock do
            next false unless @feedback.public_send(:"may_#{event}?")

            yield if block_given?
            @feedback.public_send(event) && @feedback.save
          end

          if done
            render :show
          else
            render json: ValidationError.new("feedback.#{event}", errors: @feedback.errors), status: :bad_request
          end
        end

        private def set_feedback
          @feedback = Feedback.includes(:user, :resolved_by, replies: :admin_user).find(params[:id])
          authorize! @feedback, with: ::Admin::FeedbackPolicy
        end

        private def feedback_query_params
          params.fetch(:q, {}).permit(:aasm_state_eq, :feature_name_eq, :feature_name_present, :message_cont)
        end
      end
    end
  end
end
