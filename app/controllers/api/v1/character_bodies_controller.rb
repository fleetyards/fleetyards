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
        maps = @character_bodies.filter_map { |body| body.environment&.dig("map") }
        @environment_maps = CharacterAsset.where(path: maps).joins(:file_attachment).with_attached_file.index_by(&:path)
      end
    end
  end
end
