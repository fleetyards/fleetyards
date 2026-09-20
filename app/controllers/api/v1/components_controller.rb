# frozen_string_literal: true

module Api
  module V1
    class ComponentsController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index show weapons changes]

      after_action -> { pagination_header(:components) }, only: [:index]

      # Variants of a gun that exist only inside the game files — level-of-detail
      # meshes, NPC security-network copies, turret-only and ship-bespoke builds,
      # and cosmetic skin editions that are statistically identical to their
      # base weapon. None are loadout options, and including them inflated the
      # list to 175 against the 133 erkul shows.
      WEAPON_VARIANT_KEYS = [
        "_lowpoly", "_collector", "_securitynetwork", "_bespoke", "_weak", "_shark",
        "_turret", "automatedturret",
        "_idris", "_javelin", "_bengal", "_vng_"
      ].join("|").freeze

      # Slim, unpaginated list of every ship gun in the current game version,
      # carrying only what the deflection check needs. The full component
      # serializer (prices, media, hardpoints) is far too heavy for ~200 rows.
      def weapons
        @weapons = Component
          .includes(:manufacturer)
          .where(
            category: "weapons",
            component_sub_type: "Gun",
            version: ::ScData::Source.version
          )
          .where.not(type_data: nil)
          .where("sc_key IS NULL OR sc_key !~ ?", WEAPON_VARIANT_KEYS)
          .order(name: :asc)
      end

      # One component, with the parts a list leaves out. Resolved by slug, which
      # is unique as of the catalogue work -- before that a name like "Manned
      # Turret" matched 112 rows and there was no detail page to serve.
      def show
        slug = params[:slug].to_s.downcase
        @component = Component.includes(:manufacturer).find_by!(slug:)
      end

      # What each patch changed about this component, newest first. The builds
      # these were derived from are pruned to the two or three the environment
      # keeps; the log is not.
      #
      # Scoped to the source the reader is on. The log holds a row per
      # environment and a version passes through ptu before it reaches live, so
      # the two carry rows for the same `to_version` -- unscoped, a live reader
      # would be shown a preview cycle's diffs folded into the patch they are
      # actually running.
      def changes
        component = Component.find_by!(slug: params[:slug].to_s.downcase)

        @changes = component.build_changes
          .where(environment: ::ScData::Source.current.environment)
          .newest_first
      end

      def index
        # The model has named its allowed sorts all along; this action threw them
        # away and forced `name asc` on every request. `sorting_params` is what
        # every other list endpoint uses, and it falls back to the model's
        # default rather than trusting whatever arrives. `normalize_sort_params`
        # first, because a sortable list sends `q[s]` and ransack would read a
        # leftover `s` ahead of the whitelisted `sorts`.
        normalize_sort_params(components_query_params)
        components_query_params["sorts"] = sorting_params(Component, components_query_params["sorts"])

        # `with_facts` because the filters resolve against the joined build.
        # Without it a fact condition raises rather than quietly matching the
        # column, which is the failure mode to want.
        #
        # The same flag ransack gets decides the join: for the default it is an
        # inner join to the build we are on, which already leaves out everything
        # that build does not describe. `currentVersion=false` needs the fallback
        # join, or a retired component would be filtered out by the join before
        # ransack ever sees it.
        # `catalogued` because this is a list a reader browses: an entry the game
        # never gave a display name is unreadable, and having no name it has no
        # slug either, so it has no detail page to open -- and doors and
        # subsystem controllers are ship internals nobody fits.
        @q = Component.with_facts(current_version)
          .catalogued
          .includes(:manufacturer)
          .ransack(components_query_params)

        @components = @q.result
          .page(params[:page])
          .per(per_page(Component))
      end

      # Read rather than removed from the query: `current_version` stays a
      # ransackable scope, so ransack applies it as well. The exists check it adds
      # is redundant beside the inner join and free beside the fallback one.
      private def current_version
        components_query_params.fetch(:current_version, true)
      end

      private def components_query_params
        # `description_cont` and `manufacturer_name_cont` are new -- a catalogue
        # search matching only a name cannot find "the Behring one", or a
        # component by what it does.
        #
        # `item_type_in` and `component_class_in` stay permitted even though no
        # row in the current build carries either column. Dropping them would
        # not error, it would silently stop filtering, so a client asking for
        # nothing would suddenly receive everything. They go when the endpoints
        # feeding them do.
        # A range per metric, so "shields over 5,000 HP" is a filter rather than
        # something a client has to page through and sift itself. The ransackers
        # these resolve against already exist -- they are what makes the metric
        # sorts work -- so this is the schema and the allowlist catching up.
        metric_predicates = Component::METRICS.keys.flat_map do |metric|
          [:"#{metric.underscore}_gteq", :"#{metric.underscore}_lteq"]
        end

        @components_query_params ||= params.permit(q: [
          :s, :sorts, :name_cont, :description_cont, :manufacturer_name_cont,
          :current_version, :hidden_eq, *metric_predicates,
          sorts: [], id_in: [], name_in: [], item_type_in: [], manufacturer_slug_in: [],
          component_class_in: [], category_in: [], component_sub_type_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
