# frozen_string_literal: true

module Invite
  class BaseController < ApplicationController
    def fleet
      redirect_to frontend_fleet_invite_url(slug: params[:fleet_slug], token: params[:token])
    end
  end
end
