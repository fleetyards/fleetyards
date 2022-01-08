# frozen_string_literal: true

module Frontend
  class HangarController < ApplicationController
    def index
      @user = User.find_by(['normalized_username = :value', { value: params[:username].downcase }])
      if @user.present?
        vehicle = @user.vehicles.public.includes(:model).order(flagship: :desc, name: :asc).order('models.name asc').first
        @title = I18n.t('title.frontend.public_hangar', user: username(@user.username))
        @og_type = 'article'
        @og_image = vehicle.model.store_image.url if vehicle.present?
      end

      render_frontend
    end

    private def render_frontend
      respond_to do |format|
        format.html do
          render 'frontend/index', status: :ok
        end
        format.all do
          redirect_to '/404'
        end
      end
    end

    private def username(name)
      return name if name.ends_with?('s') || name.ends_with?('x') || name.ends_with?('z')

      "#{name}'s"
    end
  end
end
