# frozen_string_literal: true

module Admin
  module Api
    module V1
      class SupporterContributionsController < ::Admin::Api::BaseController
        before_action :set_supporter_contribution, only: %i[show update destroy]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.supporter_contribution"))
        end

        def index
          authorize! with: ::Admin::SupporterContributionPolicy

          supporter_contribution_query_params["sorts"] = sorting_params(SupporterContribution, supporter_contribution_query_params[:sorts])

          q = SupporterContribution.ransack(supporter_contribution_query_params)

          @supporter_contributions = q.result(distinct: true)
            .page(params[:page])
            .per(per_page(SupporterContribution))
        end

        def stats
          authorize! with: ::Admin::SupporterContributionPolicy

          q = SupporterContribution.ransack(supporter_contribution_query_params.except("sorts"))
          @stats_scope = q.result(distinct: true)
        end

        def show
        end

        def create
          @supporter_contribution = SupporterContribution.new(supporter_contribution_params)

          authorize! @supporter_contribution, with: ::Admin::SupporterContributionPolicy

          return if @supporter_contribution.save

          render json: ValidationError.new("supporter_contribution.create", errors: @supporter_contribution.errors), status: :bad_request
        end

        def update
          return if @supporter_contribution.update(supporter_contribution_params)

          render json: ValidationError.new("supporter_contribution.update", errors: @supporter_contribution.errors), status: :bad_request
        end

        def destroy
          return if @supporter_contribution.destroy

          render json: ValidationError.new("supporter_contribution.destroy", errors: @supporter_contribution.errors), status: :bad_request
        end

        private def set_supporter_contribution
          @supporter_contribution = SupporterContribution.find(params[:id])

          authorize! @supporter_contribution, with: ::Admin::SupporterContributionPolicy
        end

        private def supporter_contribution_params
          @supporter_contribution_params ||= params.permit(
            :name, :amount_cents, :currency, :anonymous, :recurring,
            :started_at, :ended_at, :note
          )
        end

        private def supporter_contribution_query_params
          @supporter_contribution_query_params ||= params.permit(q: [
            :name_cont, :name_eq, :recurring_eq, :anonymous_eq,
            :started_at_gteq, :started_at_lteq, :ended_at_gteq, :ended_at_lteq,
            :sorts, sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
