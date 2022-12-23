# frozen_string_literal: true

module Api
  module V2
    class BaseController < ::Api::BaseController
      include PaginationV2

      def root
        respond_to do |format|
          format.html do
            render 'api/v2/base'
            # render file: Rails.public_path.join('docs', 'v2.html')
          end
          format.json do
            render json: { message: 'FleetYards.net API v2 root' }
          end
        end
      end
    end
  end
end
