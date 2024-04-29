# frozen_string_literal: true

module Admin
  class BaseController < ::Admin::ApplicationController
    layout "admin/application"

    include PrefetchHelper

    def index
      authorize! :show, :admin

      route = request.fullpath.split("?").first.sub(%r{^/}, "").tr("/", "_")
      route = "dashboard" if route.blank?

      @title = I18n.t("title.admin.#{route}") if I18n.exists?("title.admin.#{route}")

      render_frontend
    end

    def model
      authorize! :show, :admin

      @model = model_record.first
      if @model.present?
        @title = "#{@model.name} - #{@model.manufacturer.name}"
        @description = @model.description
        @og_type = "article"
        @og_image = @model.store_image.url
        add_to_prefetch(:model, @model.to_json)
      end

      render_frontend
    end

    def not_found
      authorize! :show, :admin

      respond_to do |format|
        format.html do
          render "admin/index", status: :not_found
        end
        format.json do
          render json: {code: "not_found", message: "Not Found"}, status: :not_found
        end
        format.all do
          redirect_to "/404"
        end
      end
    end

    private def render_frontend
      respond_to do |format|
        format.html do
          render "admin/index", status: :ok
        end
        format.all do
          redirect_to "/404"
        end
      end
    end

    private def model_record(id = params[:id])
      Model.where(id: id)
    end

    private def online_count
      Ahoy::Event.without_users(tracking_blocklist)
        .select(:visit_id).distinct
        .where("time > ?", 15.minutes.ago).count
    end
    helper_method :online_count

    private def tracking_blocklist
      @tracking_blocklist ||= User.where(tracking: false).pluck(:id)
    end
    helper_method :tracking_blocklist

    private def transform_for_chart(data)
      data.sort_by { |_label, count| count }.reverse
        .each_with_index.map do |(label, count), index|
        point = {
          name: label,
          y: count
        }
        if index.zero?
          point[:selected] = true
          point[:sliced] = true
        end
        point
      end
    end
  end
end
