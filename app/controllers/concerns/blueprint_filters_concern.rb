# frozen_string_literal: true

# The blueprint catalogue's filter surface, shared by the public list and by a
# fleet's list of what its members hold.
#
# The two ask for the same recipes in the same way and differ only in which
# rows they start from, so the filters, the sort whitelist, the build join and
# the owned-marker preload all live here rather than being written twice and
# drifting.
module BlueprintFiltersConcern
  extend ActiveSupport::Concern

  # `with_facts` because the filters resolve against the joined build. The same
  # flag ransack gets decides the join: the default is an inner join to the
  # build we are on, and `currentVersion=false` needs the fallback join or a
  # retired recipe would be filtered out before ransack ever saw it.
  #
  # The build, its cost tree and its sources come along: a row names the
  # materials it consumes and which sides of the law hand it out, and without
  # this the list pays four queries per row for them.
  #
  # `last_build` alongside it, because a row the current build dropped renders
  # entirely off that one -- `facts` is `build || last_build` -- and a filter
  # asking for `currentVersion=false` is exactly the request that returns
  # those rows. Preloading only the current build there put the fan-out back,
  # one query per retired row per association.
  private def filtered_blueprints(scope = Blueprint.all)
    # `normalize_sort_params` first, because a sortable list sends `q[s]` and
    # ransack would read a leftover `s` ahead of the whitelisted `sorts`.
    normalize_sort_params(blueprints_query_params)
    blueprints_query_params["sorts"] = sorting_params(Blueprint, blueprints_query_params["sorts"])

    # The build-reading filters are taken off the query: ransack would either
    # skip them or apply them against the wrong build.
    @q = scope.with_facts(current_version)
      .includes(
        :craftable,
        build: [:craftable, :sources, {cost_slots: {options: :commodity}}],
        last_build: [:craftable, :sources, {cost_slots: {options: :commodity}}]
      )
      .ransack(
        blueprints_query_params.except(
          :from_org, :source_alignment_in, :consuming_commodity, :with_known_source, :owned
        )
      )

    owned_filter(source_filters(@q.result))
  end

  # The filters that read a build, applied here rather than through
  # ransack.
  #
  # Two reasons, and each one alone is enough. Ransack turns a scope's "false"
  # into a boolean and then skips the scope entirely, so `withKnownSource=false`
  # would quietly return the whole catalogue -- 1,607 rather than 901. And each
  # of them has to know whether the request is reading the build we are on or
  # falling back to the last one that described the recipe, which a ransack
  # scope cannot be told: it is handed one argument.
  #
  # Filtering the current build while rendering the fallback is the bug this
  # shape exists to avoid -- it drops a retired recipe whose retained build does
  # name the org being asked for, and lets one through `withKnownSource=false`
  # whose own response says a source is known.
  private def source_filters(scope)
    current_only = current_version
    # The *served* build, which is what `with_facts` joins. The configured one
    # is a different build while its load has not finished, and filtering that
    # one while rendering the other answers about a build the response never
    # shows.
    source = Blueprint.served_source

    scope = scope.from_org(org_filter, source, current_only:) if org_filter.present?
    scope = scope.from_alignment(alignment_filter, source, current_only:) if alignment_filter.present?
    scope = scope.consuming_commodity(commodity_filter, source, current_only:) if commodity_filter.present?

    return scope if known_source_filter.nil?

    scope.with_known_source(
      ActiveModel::Type::Boolean.new.cast(known_source_filter), source, current_only:
    )
  end

  # The same trap: ransack skips a scope whose value is false,
  # so `owned=false` would answer "the recipes I do not have" with all of them.
  #
  # Off the resolved reader rather than off a parameter -- whose recipes are
  # being asked about is never the caller's to name.
  private def owned_filter(scope)
    flag = blueprints_query_params[:owned]

    return scope if flag.nil?

    if ActiveModel::Type::Boolean.new.cast(flag)
      scope.owned_by(current_resource_owner)
    else
      scope.not_owned_by(current_resource_owner)
    end
  end

  # The subset of these blueprints the reader holds, in one query rather than
  # one per row. Empty when signed out, which is what the payload's
  # `owned: false` says.
  private def owned_ids_for(blueprints)
    holder = current_resource_owner

    return Set.new if holder.blank?

    Set.new(
      UserBlueprint.where(user_id: holder.id, blueprint_id: blueprints.map(&:id)).pluck(:blueprint_id)
    )
  end

  private def org_filter
    blueprints_query_params[:from_org]
  end

  # Which side of the law hands the recipe out. A list from the start -- both
  # sides hand out the same pool often enough that one value at a time would be
  # the wrong question -- so there is no scalar spelling to combine with.
  private def alignment_filter
    blueprints_query_params[:source_alignment_in]
  end

  # Both spellings, combined: the scalar is what the filter shipped with and the
  # list is what a multi-select sends, and asking both ways asks for the union
  # rather than for whichever the controller looked at first.
  private def commodity_filter
    [
      blueprints_query_params[:consuming_commodity],
      *blueprints_query_params[:consuming_commodity_in]
    ].compact.uniq
  end

  private def known_source_filter
    blueprints_query_params[:with_known_source]
  end

  private def current_version
    blueprints_query_params.fetch(:current_version, true)
  end

  private def blueprints_query_params
    @blueprints_query_params ||= params.permit(q: [
      :s, :sorts, :name_cont, :current_version,
      :craftable_type_eq, :craftable_id_eq,
      # The ones the controller applies itself -- these and
      # `source_alignment_in` below. Permitted like any other: they are read
      # from here rather than off `params` directly, so an unpermitted one
      # would silently stop filtering.
      :from_org, :with_known_source, :owned,
      :craft_time_lteq, :craft_time_gteq,
      :consuming_commodity,
      sorts: [], id_in: [], name_in: [], craftable_type_in: [],
      consuming_commodity_in: [], source_alignment_in: []
    ]).fetch(:q, {})
  end
end
