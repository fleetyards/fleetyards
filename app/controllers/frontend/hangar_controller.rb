# frozen_string_literal: true

module Frontend
  class HangarController < ApplicationController
    def index
      @user = User.find_by(['lower(username) = :value', { value: params[:username].downcase }])
      if @user.present?
        vehicle = @user.vehicles.public.includes(:model).order(flagship: :desc, name: :asc).order('models.name asc').first
        @title = I18n.t('title.frontend.public_hangar', user: username(@user.username))
        @og_type = 'article'
        @og_image = vehicle.model.store_image.url if vehicle.present?
      end
      render 'frontend/index'
    end

    private def username(name)
      return name if name.ends_with?('s') || name.ends_with?('x') || name.ends_with?('z')

      "#{name}'s"
    end
  end
end
