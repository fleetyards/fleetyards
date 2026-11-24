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

      # What the current patch of an environment brought, for the landing page.
      # Cached on the two builds and when the newer one was last written, so a
      # re-load of the same version is picked up and every visitor in between
      # reads one answer.
      #
      # Its own parameter rather than `scDataSource`: the section switches
      # between the two on its own, whichever build the rest of the site reads.
      def patch_summary
        summary = ::ScData::PatchSummary.for(params.fetch(:environment, ::ScData::PatchSummary::LIVE).to_s)
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

      # How much each catalogue moved between two builds.
      def diff_summary
        return unless set_diff_builds

        @code = diff_code
        @results = ::ScData::BuildDiff::CATALOGUES.keys.index_with { |catalogue| diff_of(catalogue) }
      end

      # One catalogue's records between two builds, with both values of every
      # fact that moved. `kind`, `field` and `search` narrow the list, the counts
      # beside it stay those of the whole comparison.
      def diff
        return unless set_diff_builds

        catalogue = params[:catalogue]
        return not_found unless ::ScData::BuildDiff::CATALOGUES.key?(catalogue)

        @result = diff_of(catalogue)
        rows = narrow(@result.entries)
        @entries = Kaminari.paginate_array(rows).page(page_params).per(diff_per_page)
        @links = ::ScData::BuildDiffLinks.new(catalogue, @entries).call
        @contexts = ::ScData::BuildDiffContext.new(catalogue, @entries, from: @from, to: @to).call
      end

      DIFF_PER_PAGE = 48
      DIFF_PER_PAGE_MAX = 240

      private def diff_per_page
        size = per_page_params.to_i

        size.positive? ? [size, DIFF_PER_PAGE_MAX].min : DIFF_PER_PAGE
      end

      private def set_diff_builds
        @from = recorded_build(params[:from])
        @to = recorded_build(params[:to])
        return true if @from && @to

        not_found
        false
      end

      # Loadouts name parts and ships out of these as well as reading slots.
      DIFF_BUILDS = {"loadouts" => [HardpointBuild, ComponentBuild, ModelBuild, ModelModuleBuild]}.freeze

      # Where visibility and the names behind references live.
      DIFF_SUBJECTS = [Model, ModelModule, Location, Manufacturer].freeze

      # Counted as well as timed: a retired row leaves without moving the newest
      # timestamp.
      private def diff_of(catalogue)
        builds = DIFF_BUILDS.fetch(catalogue) { [::ScData::BuildDiff::CATALOGUES.fetch(catalogue).fetch(:build).constantize] }
        state = builds.product([@from, @to]).map { |klass, source|
          fingerprint(klass.where(environment: source.environment, version: source.version))
        }

        Rails.cache.fetch(["sc-data/diff/v2", catalogue, @from.version, @to.version, diff_code, *state, *diff_subject_state], expires_in: 1.day) do
          ::ScData::BuildDiff.new(catalogue, from: @from, to: @to, same_code: diff_code == ::ScData::CodeDigest::SAME).call
        end
      end

      private def diff_code
        @diff_code ||= ::ScData::CodeDigest.relation(@from, @to)
      end

      private def diff_subject_state
        @diff_subject_state ||= DIFF_SUBJECTS.map { |klass| fingerprint(klass.all) }
      end

      private def fingerprint(scope)
        count, written = scope.pick(Arel.sql("COUNT(*), MAX(updated_at)"))

        "#{count}-#{written.to_f}"
      end

      private def narrow(entries)
        entries = entries.select { |entry| entry.kind == params[:kind] } if params[:kind].present?
        entries = entries.select { |entry| entry.fields.any? { |field| field.field == params[:field] } } if params[:field].present?

        if params[:search].present?
          term = params[:search].to_s.downcase
          entries = entries.select { |entry| entry.name.downcase.include?(term) }
        end

        entries
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
