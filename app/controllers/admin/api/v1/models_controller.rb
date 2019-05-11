# frozen_string_literal: true

module Admin
  module Api
    module V1
      class ModelsController < ::Admin::Api::BaseController
        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t('messages.record_not_found.model', slug: params[:slug]))
        end

        def images
          authorize! :show, :admin_api_models
          model = Model.find(params[:id])
          @images = model.images
                         .order('images.created_at desc')
        end
      end
    end
  end
end
