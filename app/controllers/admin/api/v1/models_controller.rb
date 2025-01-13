# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelsController < ::Admin::Api::BaseController
        before_action :set_model, only: %i[show update destroy use_rsi_image images reload_one]
        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.model", slug: params[:slug]))
        end

        def index
          authorize! :read, Model

          @q = index_scope

          @models = @q.result
            .page(params[:page])
            .per(per_page(Model))
        end

        def show
          authorize! :show, @model
        end

        def options
          authorize! :read, Model

          @q = index_scope

          @models = @q.result
            .page(params[:page])
            .per(per_page(Model))
        end

        def production_states
          authorize! :read, Model

          @production_states = Model.production_status_filters
        end

        def name_diff
          authorize! :read, Model

          @q = Model.where("name != rsi_name AND rsi_id IS NOT NULL").ransack(params[:q])

          @q.sorts = "name asc" if @q.sorts.empty?

          @models = @q.result
            .page(params.fetch(:page) { nil })
            .per(40)
        end

        def price_diff
          authorize! :read, Model

          @q = Model.where("pledge_price != last_pledge_price AND rsi_id IS NOT NULL").ransack(params[:q])

          @q.sorts = "name asc" if @q.sorts.empty?

          @models = @q.result
            .page(params.fetch(:page) { nil })
            .per(40)
        end

        def create
          authorize! :create, Model

          @model = Model.new(model_params)

          return if @model.save

          render json: ValidationError.new("model.create", errors: @model.errors), status: :bad_request
        end

        def update
          authorize! :update, @model

          return if @model.update(model_params.merge(author_id: current_user.id, update_reason: :custom))

          render json: ValidationError.new("model.update", errors: @model.errors), status: :bad_request
        end

        def destroy
          authorize! :destroy, @model

          return if @model.destroy

          render json: ValidationError.new("model.destroy", errors: @model.errors), status: :bad_request
        end

        def use_rsi_image
          authorize! :update, @model

          return if @model.update(remote_store_image_url: @model.rsi_store_image_url)

          Rails.logger.info @model.errors.to_a.to_yaml

          render json: ValidationError.new("model.use_rsi_image", errors: @model.errors), status: :bad_request
        end

        def images
          authorize! :images, @model
        end

        def reload_matrix
          authorize! :reload, :admin_api_models

          Loaders::ModelsJob.perform_async

          render json: {message: "Jobs enqueued"}, status: :ok
        end

        def reload_scdata
          authorize! :manage, Model

          Loaders::ScData::ModelsJob.perform_async

          render json: {message: "Jobs enqueued"}, status: :ok
        end

        def reload_loaners
          authorize! :manage, Model

          Loaders::LoanerJob.perform_async

          render json: {message: "Jobs enqueued"}, status: :ok
        end

        def reload_paints
          authorize! :manage, Model

          Loaders::PaintsImportJob.perform_async

          render json: {message: "Jobs enqueued"}, status: :ok
        end

        def reload_one
          authorize! :reload, @model

          Loaders::ModelJob.perform_async(@model.rsi_id)
          Loaders::ScData::ModelJob.perform_async(@model.id) if @model.sc_identifier.present?

          render json: {message: "Jobs enqueued"}, status: :ok
        end

        private def set_model
          @model = Model.find(params[:id])
        end

        private def index_scope
          model_query_params["sorts"] ||= sorting_params(Model)

          Model.includes([:manufacturer]).ransack(model_query_params)
        end

        private def model_query_params
          @model_query_params ||= query_params(
            :search_cont, :name_cont, :id_eq, :front_view_blank, :fleetchart_image_blank,
            :top_view_colored_blank, :sc_identifier_blank, :holo_blank,
            name_in: [], id_in: [], id_not_in: [], production_status_in: [],
            manufacturer_in: []
          )
        end

        private def model_params
          @model_params ||= params.permit(
            :name, :description, :hidden, :active, :ground, :mass, :min_crew, :max_crew,
            :scm_speed, :scm_speed_boosted, :max_speed, :reverse_speed_boosted, :yaw, :yaw_boosted,
            :pitch, :pitch_boosted, :roll, :roll_boosted, :sc_identifier, :erkul_identifier,
            :manufacturer_id, :rsi_id, :base_model_id, :production_status, :production_note,
            :classification, :focus, :size, :dock_size, :length, :beam, :height, :on_sale,
            :store_url, :sales_page_url, :price, :pledge_price, :last_pledge_price, :cargo,
            :cargo_holds, :hydrogen_fuel_tank_size, :hydrogen_fuel_tanks, :quantum_fuel_tank_size,
            :quantum_fuel_tanks, :store_image_new
          )
        end
      end
    end
  end
end
