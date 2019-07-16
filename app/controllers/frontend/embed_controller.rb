# frozen_string_literal: true

module Frontend
  class EmbedController < ApplicationController
    protect_from_forgery except: %i[embed embed_v2]

    def embed
      respond_to do |format|
        format.js do
          render 'frontend/embed', layout: false
        end
        format.all do
          redirect_to '/404'
        end
      end
    end

    def embed_test
      render 'frontend/embed_test', layout: 'embed_test'
    end

    def embed_v2
      respond_to do |format|
        format.js do
          render 'frontend/embed_v2', layout: false
        end
        format.all do
          redirect_to '/404'
        end
      end
    end

    def embed_v2_test
      render 'frontend/embed_test', layout: 'embed_v2_test'
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
