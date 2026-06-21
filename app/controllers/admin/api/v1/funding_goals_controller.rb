# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FundingGoalsController < ::Admin::Api::BaseController
        before_action :set_funding_goal, only: %i[show update destroy]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.funding_goal"))
        end

        def index
          authorize! with: ::Admin::FundingGoalPolicy

          funding_goal_query_params["sorts"] = sorting_params(FundingGoal, funding_goal_query_params[:sorts])

          q = FundingGoal.ransack(funding_goal_query_params)

          @funding_goals = q.result(distinct: true)
            .page(params[:page])
            .per(per_page(FundingGoal))
        end

        def show
        end

        def create
          @funding_goal = FundingGoal.new(funding_goal_params)

          authorize! @funding_goal, with: ::Admin::FundingGoalPolicy

          return if @funding_goal.save

          render json: ValidationError.new("funding_goal.create", errors: @funding_goal.errors), status: :bad_request
        end

        def update
          return if @funding_goal.update(funding_goal_params)

          render json: ValidationError.new("funding_goal.update", errors: @funding_goal.errors), status: :bad_request
        end

        def destroy
          return if @funding_goal.destroy

          render json: ValidationError.new("funding_goal.destroy", errors: @funding_goal.errors), status: :bad_request
        end

        private def set_funding_goal
          @funding_goal = FundingGoal.find(params[:id])

          authorize! @funding_goal, with: ::Admin::FundingGoalPolicy
        end

        private def funding_goal_params
          @funding_goal_params ||= params.permit(
            :title, :description, :amount_cents, :currency, :effective_from, :ended_at
          )
        end

        private def funding_goal_query_params
          @funding_goal_query_params ||= params.permit(q: [
            :title_cont,
            :amount_cents_eq, :amount_cents_gteq, :amount_cents_lteq,
            :effective_from_eq, :effective_from_gteq, :effective_from_lteq,
            :sorts, sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
