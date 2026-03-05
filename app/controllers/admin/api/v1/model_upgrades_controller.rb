# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelUpgradesController < ::Admin::Api::BaseController
        before_action :set_model_upgrade, only: %i[show update destroy link unlink]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          authorize! with: ::Admin::ModelUpgradePolicy

          model_upgrade_query_params["sorts"] = sorting_params(ModelUpgrade, model_upgrade_query_params[:sorts], "created_at desc")

          @q = authorized_scope(ModelUpgrade.all).ransack(model_upgrade_query_params)

          @model_upgrades = @q.result
            .includes(:upgrade_kits, :models)
            .page(params[:page])
            .per(per_page(ModelUpgrade))
        end

        def show
        end

        def create
          @model_upgrade = ModelUpgrade.new(model_upgrade_params)

          authorize! @model_upgrade, with: ::Admin::ModelUpgradePolicy

          if @model_upgrade.save
            if params[:model_id].present?
              UpgradeKit.find_or_create_by!(
                model_id: params[:model_id],
                model_upgrade_id: @model_upgrade.id
              )
            end

            render :show, status: :created
          else
            render json: ValidationError.new("model_upgrade.create", errors: @model_upgrade.errors), status: :bad_request
          end
        end

        def update
          if @model_upgrade.update(model_upgrade_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("model_upgrade.update", errors: @model_upgrade.errors), status: :bad_request
          end
        end

        def destroy
          @model_upgrade.destroy

          head :no_content
        end

        def link
          model = Model.find(params[:model_id])

          UpgradeKit.find_or_create_by!(
            model_id: model.id,
            model_upgrade_id: @model_upgrade.id
          )

          render :show, status: :ok
        end

        def unlink
          model = Model.find(params[:model_id])

          upgrade_kit = UpgradeKit.find_by!(
            model_id: model.id,
            model_upgrade_id: @model_upgrade.id
          )
          upgrade_kit.destroy!

          render :show, status: :ok
        end

        private def set_model_upgrade
          @model_upgrade = ModelUpgrade.find(params[:id])

          authorize! @model_upgrade, with: ::Admin::ModelUpgradePolicy
        end

        private def model_upgrade_params
          @model_upgrade_params ||= params.permit(
            :name, :description, :pledge_price,
            :active, :hidden, :store_image
          )
        end

        private def model_upgrade_query_params
          @model_upgrade_query_params ||= params.permit(q: [
            :name_in, :id_eq, :name_cont, :name_eq,
            :upgrade_kits_model_id_eq, :sorts,
            sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
