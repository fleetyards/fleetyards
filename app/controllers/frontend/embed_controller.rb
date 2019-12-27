# frozen_string_literal: true

module Frontend
  class EmbedController < ApplicationController
    protect_from_forgery except: %i[index index_v2]

    def index
      respond_to do |format|
        format.js do
          render 'frontend/embed', layout: false
        end
        format.all do
          redirect_to '/404'
        end
      end
    end

    def test
      render 'frontend/embed_test', layout: 'embed_test'
    end

    def index_v2
      respond_to do |format|
        format.js do
          render 'frontend/embed_v2', layout: false
        end
        format.all do
          redirect_to '/404'
        end
      end
    end

    def test_v2
      render 'frontend/embed_test', layout: 'embed_v2_test'
    end

    def test_v2_username
      render 'frontend/embed_test', layout: 'embed_v2_username_test'
    end
  end
end
