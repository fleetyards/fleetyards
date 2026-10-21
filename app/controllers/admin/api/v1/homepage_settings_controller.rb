# frozen_string_literal: true

module Admin
  module Api
    module V1
      class HomepageSettingsController < ::Admin::Api::BaseController
        before_action :set_homepage_setting

        def show
        end

        def update
          return if @homepage_setting.update(homepage_setting_params)

          render json: ValidationError.new("homepage_setting.update", errors: @homepage_setting.errors), status: :bad_request
        end

        private def set_homepage_setting
          @homepage_setting = HomepageSetting.current

          authorize! @homepage_setting, with: ::Admin::HomepageSettingPolicy
        end

        private def homepage_setting_params
          @homepage_setting_params ||= params.permit(:featured_random, :featured_hidden, featured_model_ids: [])
        end
      end
    end
  end
end
