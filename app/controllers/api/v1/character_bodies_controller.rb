# frozen_string_literal: true

module Api
  module V1
    class CharacterBodiesController < ::Api::PublicBaseController
      include DressingRoomFeatureConcern

      skip_verify_authorized only: %i[index]

      before_action :check_dressing_room_feature

      def index
        @character_bodies = CharacterBody.with_holo
        @context = ::Chf::Context.current
      end
    end
  end
end
