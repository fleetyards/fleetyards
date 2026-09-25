# frozen_string_literal: true

module Api
  module V1
    class EquipmentController < ::Api::PublicBaseController
      skip_verify_authorized only: %i[index show]

      after_action -> { pagination_header(:equipment) }, only: [:index]

      # Every numeric fact a reader can bound, from the same list the sorts come
      # from, so a sortable figure is always a filterable one too.
      RANGE_PREDICATES = Equipment::SORTABLE_METRICS.flat_map do |metric|
        [:"#{metric.underscore}_gteq", :"#{metric.underscore}_lteq"]
      end.freeze

      def index
        # `id` last so equal values have one order: names repeat across
        # colourways, and without it a page boundary through a run of them could
        # show one item twice and skip another.
        normalize_sort_params(equipment_query_params)
        equipment_query_params["sorts"] = sorting_params(Equipment, equipment_query_params["sorts"]) + ["id asc"]

        # Skins, NPC loadouts and event copies carry their own record but are
        # not something a player holds, so the list leaves them out. So does
        # gear a later patch stopped shipping, unless currentVersion=false asks
        # for it -- the rows stay so old ledger entries still resolve.
        # `visible` takes the flag rather than a separate `current_version`: for
        # the default it joins the build we are on, and an inner join to it
        # already leaves out what that build does not describe.
        @q = Equipment.visible(current_version)
          .includes(:manufacturer, :item_prices)
          .ransack(equipment_query_params)

        @equipment = @q.result
          .page(page_params)
          .per(per_page(Equipment))
      end

      # The same `visible` rule the list applies, so no link reaches a page the
      # list would refuse to show -- but against every build rather than the one
      # we are on, because an item a patch dropped still has a page. It says it
      # is retired instead of disappearing from under a bookmark or a ledger
      # entry.
      def show
        @equipment = Equipment.visible(false)
          .includes(:manufacturer, :item_prices)
          .find_by!(slug: params[:slug].to_s.downcase)
      end

      # Taken out of the ransack params rather than left in them: it is a scope,
      # not a column, and ransack would try to match a `current_version` field.
      private def current_version
        equipment_query_params.delete(:current_version) { true }
      end

      # `nameCont` matched the slug as well while `name` was aliased to
      # `name_or_slug`, and published clients rely on that, so it keeps meaning
      # it now that `name` is its own attribute.
      private def equipment_query_params
        @equipment_query_params ||= permitted_query_params.tap do |query|
          term = query.delete(:name_cont)
          query[:name_or_slug_cont] ||= term if term.present?
        end
      end

      private def permitted_query_params
        params.permit(q: [
          :s, :sorts, :name_cont, :name_or_slug_cont, :current_version, *RANGE_PREDICATES,
          sorts: [], id_in: [], name_in: [], slug_in: [], equipment_type_in: [], item_type_in: [],
          sub_type_in: [], weapon_class_in: [], slot_in: [], size_in: [], grade_in: [],
          manufacturer_slug_in: []
        ]).fetch(:q, {})
      end
    end
  end
end
