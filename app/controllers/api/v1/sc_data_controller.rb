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
        @loading_screens = LoadingScreen.with_attached_image
          .where(version: @builds.map(&:version))
          .sort_by(&:name)
          .group_by(&:version)
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

      # What the current live patch brought, for the landing page. Cached on the
      # two builds and when the newer one was last written, so a re-load of the
      # same version is picked up and every visitor in between reads one answer.
      def patch_summary
        summary = ::ScData::PatchSummary.for("live")
        return not_found if summary.blank?

        written = ::ScData::PatchSummary::CATALOGUES.values.map { |build_class|
          build_class.where(environment: summary.to.environment, version: summary.to.version).maximum(:updated_at)
        }.compact.max

        @summary = Rails.cache.fetch(["sc-data/patch-summary", summary.from.version, summary.to.version, written&.to_i], expires_in: 1.day) do
          summary.call
        end

        models = Model.visible.active
          .where(id: @summary[:new_ship_ids] + @summary[:ship_changes].pluck(:id))
          .index_by(&:id)
        @new_ships = @summary[:new_ship_ids].filter_map { |id| models[id] }
        @ship_changes = @summary[:ship_changes].filter_map { |change| {model: models[change[:id]], fields: change[:fields]} if models[change[:id]] }

        slugs = {
          "components" => Component.where(id: @summary[:item_changes].select { |change| change[:kind] == "components" }.pluck(:id)).pluck(:id, :slug).to_h,
          "equipment" => Equipment.where(id: @summary[:item_changes].select { |change| change[:kind] == "equipment" }.pluck(:id)).pluck(:id, :slug).to_h
        }
        @item_changes = @summary[:item_changes].map { |change| change.merge(slug: slugs.dig(change[:kind], change[:id])) }

        @latest_arrivals_version, @latest_arrivals = latest_arrivals
      end

      # The ships the most recent patch that brought any brought, for a patch
      # that brought none -- so the section can still say what is newest.
      private def latest_arrivals
        version = Model.visible.active.where.not(first_seen_version: nil).distinct.pluck(:first_seen_version)
          .max_by { |candidate| ::ScData::Source.new(environment: "live", version: candidate).precedence }
        return [nil, []] if version.blank?

        [version, Model.visible.active.where(first_seen_version: version).order(:name).to_a]
      end

      private def recorded_build(version)
        return if version.blank?

        ::ScData::Source.recorded.find { |source| source.version == version }
      end
    end
  end
end
