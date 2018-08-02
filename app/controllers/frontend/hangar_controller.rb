# frozen_string_literal: true

module Frontend
  class HangarController < ApplicationController
    def show
      @title = I18n.t('title.frontend.hangar')
      render 'frontend/index'
    end

    def public
      @user = User.find_by(username: params[:username])
      if @user.present?
        vehicle = @user.vehicles.includes(:model).order(flagship: :desc, purchased: :desc, name: :asc).order('models.name asc').first
        @title = I18n.t('title.frontend.public_hangar', user: username(@user.username))
        @og_type = 'article'
        @og_image = vehicle.model.store_image.url if vehicle.present?
      end
      render 'frontend/index'
    end

    private def username(name)
      if name.ends_with?('s') || name.ends_with?('x') || name.ends_with?('z')
        return name
      end
      "#{name}'s"
    end
  end
end
