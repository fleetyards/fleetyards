# frozen_string_literal: true

module Short
  class BaseController < ApplicationController
    def hangar
      redirect_to frontend_public_hangar_url(username: params[:username])
    end

    def fleet_invite
      redirect_to frontend_fleet_invite_url(token: params[:token])
    end
  end
end
