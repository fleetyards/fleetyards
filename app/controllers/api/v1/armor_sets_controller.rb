# frozen_string_literal: true

module Api
  module V1
    class ArmorSetsController < ::Api::PublicBaseController
      include DressingRoomFeatureConcern

      skip_verify_authorized only: %i[index]

      before_action :check_dressing_room_feature

      def index
        @armor_sets = ::DressingRoom::ArmorSets.new
      end
    end
  end
end
