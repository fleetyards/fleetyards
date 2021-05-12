# frozen_string_literal: true

module Frontend
  class ServiceWorkerController < ApplicationController
    protect_from_forgery except: %i[index precache_manifest]

    def index
      respond_to do |format|
        format.js do
          render "#{Rails.root}/public#{ActionController::Base.helpers.asset_pack_path('service_worker.js')}", layout: false
        end
        format.all do
          redirect_to '/404'
        end
      end
    end

    def precache_manifest
      respond_to do |format|
        format.js do
          render 'frontend/precache_manifest', layout: false
        end
        format.all do
          redirect_to '/404'
        end
      end
    end
  end
end
