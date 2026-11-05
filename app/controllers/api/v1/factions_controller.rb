# frozen_string_literal: true

module Api
  module V1
    class FactionsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index show]

      # Every faction at once: the export declares fewer than 40, and sorting
      # by a name read through the build is simpler in Ruby than in a join.
      def index
        @factions = Faction.current_version
          .includes(:build, :last_build, logo_attachment: :blob)
          .sort_by { |faction| faction.name.to_s.downcase }
        @mission_counts = Faction.mission_counts
      end

      def show
        @faction = Faction.current_version
          .includes(build: :ladders, last_build: :ladders, logo_attachment: :blob)
          .find_by!(slug: params[:slug].to_s.downcase)
        @awards = @faction.ladder_awards
      end
    end
  end
end
