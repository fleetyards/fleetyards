# frozen_string_literal: true

module Api
  module V1
    class ScDataController < ::Api::BaseController
      skip_verify_authorized

      before_action :authenticate_user!, only: []

      def current_version
        render json: {version: Imports::ScData::AllImport.current_version}, status: :ok
      end

      # Which builds a reader may be pointed at, for the source switch to be
      # built from. Only sources a catalogue carries builds for: an environment
      # nothing has loaded would answer every question with nothing.
      def sources
        @sources = ::ScData::Source.available
      end

      # Every build there is a row for, which is a different list from
      # `sources`: that one hides everything behind the default, and a
      # comparison needs exactly what it hides. It also reaches back past the
      # config, which names one version per environment.
      def builds
        @builds = ::ScData::Source.recorded
      end

      # What two builds say differently. Both sides are named by version alone,
      # because a version names its environment -- `4.10.1-ptu.12578875` -- so
      # there is no pair of parameters to keep consistent.
      #
      # Hardpoints are left out on purpose. They are per slot rather than per
      # catalogue entry, so a diff of 22,561 of them is a ship's loadout
      # question and belongs on a ship, not in a summary of a build.
      CATALOGUES = {
        "components" => ComponentBuild,
        "equipment" => EquipmentBuild,
        "commodities" => CommodityBuild,
        "models" => ModelBuild
      }.freeze

      def compare
        @from = recorded_build(params[:from])
        @to = recorded_build(params[:to])

        # Not found rather than a validation error: the parameter is well formed
        # and names a build nothing has a row for.
        return not_found if @from.blank? || @to.blank?

        @comparisons = CATALOGUES.transform_values do |build_class|
          ::ScData::BuildCompare.new(build_class, from: @from, to: @to).call
        end
      end

      private def recorded_build(version)
        return if version.blank?

        ::ScData::Source.recorded.find { |source| source.version == version }
      end
    end
  end
end
