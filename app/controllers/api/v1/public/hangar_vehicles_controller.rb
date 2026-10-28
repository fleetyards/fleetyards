# frozen_string_literal: true

module Api
  module V1
    module Public
      # One ship of a public hangar, for a link that opens it -- a shared plaque.
      # Found by its address, the id or the serial it leads with.
      class HangarVehiclesController < ::Api::PublicBaseController
        self.resource_owner_scopes = HANGAR_READER_SCOPES

        include PublicHangarOwnerConcern

        def show
          @vehicle = @user.vehicles.purchased.public.at_address(params[:id]).first!
        end
      end
    end
  end
end
