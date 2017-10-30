# frozen_string_literal: true

module Api
  module V1
    class BaseController < ::Api::BaseController
      def root
        respond_to do |format|
          format.html do
            render file: Rails.public_path.join('docs', 'v1.html')
          end
          format.json do
            render json: { message: 'FleetYards.net API v1 root' }
          end
        end
      end
    end
  end
end
