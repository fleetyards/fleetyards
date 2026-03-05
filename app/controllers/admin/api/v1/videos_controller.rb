# frozen_string_literal: true

module Admin
  module Api
    module V1
      class VideosController < ::Admin::Api::BaseController
        before_action :set_video, only: %i[show update destroy]

        def index
          authorize! with: ::Admin::VideoPolicy

          video_query_params["sorts"] = "created_at desc"

          @q = authorized_scope(Video.all).ransack(video_query_params)

          @videos = @q.result
            .page(params.fetch(:page, nil))
            .per(params.fetch(:per_page, nil))
        end

        def create
          @video = Video.new(video_params)

          authorize! @video, with: ::Admin::VideoPolicy

          if @video.save
            render :show, status: :created
          else
            render json: ValidationError.new("video.create", errors: @video.errors), status: :bad_request
          end
        end

        def show
        end

        def update
          if @video.update(video_params)
            render :show, status: :ok
          else
            render json: ValidationError.new("video.update", errors: @video.errors), status: :bad_request
          end
        end

        def destroy
          @video.destroy

          head :no_content
        end

        private def set_video
          @video = Video.find(params[:id])

          authorize! @video, with: ::Admin::VideoPolicy
        end

        private def video_params
          @video_params ||= params.permit(
            :model_id, :url, :video_type
          )
        end

        private def video_query_params
          @video_query_params ||= params.permit(q: [
            :model_id_eq, :video_type_eq, :sorts
          ]).fetch(:q, {})
        end
      end
    end
  end
end
