# frozen_string_literal: true

module Frontend
  class HangarWorker < ApplicationController
    def index
      @user = User.find_by(['lower(username) = :value', { value: params[:username].downcase }])
      if @user.present?
        vehicle = @user.vehicles.purchased.includes(:model).order(flagship: :desc, name: :asc).order('models.name asc').first
        @title = I18n.t('title.frontend.public_hangar', user: username(@user.username))
        @og_type = 'article'
        @og_image = vehicle.model.store_image.url if vehicle.present?
      end
      render 'frontend/index'
    end
  end
end
