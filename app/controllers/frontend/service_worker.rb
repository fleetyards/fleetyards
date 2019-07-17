# frozen_string_literal: true

module Frontend
  class ServiceWorker < ApplicationController
    protect_from_forgery except: %i[index precache_manifest]

    def index
      respond_to do |format|
        format.js do
          render 'frontend/service_worker', layout: false
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
