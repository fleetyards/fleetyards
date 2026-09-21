# frozen_string_literal: true

# The mission catalogue's filter surface.
#
# Separate from the controller for the reason `BlueprintFiltersConcern` is: the
# build join, the sort whitelist and the filters that have to be applied outside
# ransack belong together, and a second list of missions -- an org's page, a
# blueprint's "where it drops" -- will want the same ones.
module GameMissionFiltersConcern
  extend ActiveSupport::Concern

  # `with_facts` because the filters resolve against the joined build. The same
  # flag ransack gets decides the join: the default is an inner join to the
  # build we are on, and `currentVersion=false` needs the fallback join or a
  # retired mission would be filtered out before ransack ever saw it.
  #
  # `last_build` is preloaded alongside `build`, because a row the current build
  # dropped renders entirely off that one -- `facts` is `build || last_build` --
  # and `currentVersion=false` is exactly the request that returns those rows.
  private def filtered_missions(scope = nil)
    scope ||= GameMission.named(GameMission.served_source, current_only: current_version)
    # `normalize_sort_params` first, because a sortable list sends `q[s]` and
    # ransack would read a leftover `s` ahead of the whitelisted `sorts`.
    normalize_sort_params(missions_query_params)
    missions_query_params["sorts"] = sorting_params(GameMission, missions_query_params["sorts"])

    @q = scope.with_facts(current_version)
      .includes(build: :rewards, last_build: :rewards)
      .ransack(missions_query_params.except(:released, :rewarding, :rewarding_in, :from_org))

    build_filters(@q.result)
  end

  # The filters that read a build, applied here rather than through ransack.
  #
  # Two reasons and either alone is enough. Ransack turns a scope's "false" into
  # a boolean and then skips the scope, so `released=false` would quietly return
  # the whole catalogue rather than the 349 contracts the build is not offering.
  # And each of these has to know whether the request reads the build we are on
  # or falls back to the last one that described the mission, which a ransack
  # scope cannot be told: it is handed one argument.
  private def build_filters(scope)
    current_only = current_version
    # The *served* build, which is what `with_facts` joins. The configured one
    # is a different build while its load has not finished, and filtering that
    # one while rendering the other answers about a build the response never
    # shows.
    source = GameMission.served_source

    scope = scope.from_org(org_filter, source, current_only:) if org_filter.present?
    scope = scope.rewarding(reward_filter, source, current_only:) if reward_filter.present?

    return scope if released_filter.nil?

    return scope.released(source, current_only:) if ActiveModel::Type::Boolean.new.cast(released_filter)

    scope.where.not(id: GameMission.released(source, current_only:).select(:id))
  end

  private def org_filter
    missions_query_params[:from_org]
  end

  # Both spellings, combined: the scalar is what a single select sends and the
  # list is what a multi-select does, and asking both ways asks for the union
  # rather than for whichever the controller happened to look at first.
  private def reward_filter
    [
      missions_query_params[:rewarding],
      *missions_query_params[:rewarding_in]
    ].compact.uniq
  end

  private def released_filter
    missions_query_params[:released]
  end

  private def current_version
    missions_query_params.fetch(:current_version, true)
  end

  private def missions_query_params
    @missions_query_params ||= params.permit(q: [
      :s, :sorts, :name_cont, :current_version,
      :kind_eq, :alignment_eq, :org_key_eq, :org_name_eq,
      :min_standing_eq, :max_standing_eq,
      :difficulty_mechanical_skill_lteq, :difficulty_mechanical_skill_gteq,
      :difficulty_risk_of_loss_lteq, :difficulty_risk_of_loss_gteq,
      # The ones the controller applies itself. Permitted like any other: they
      # are read from here rather than off `params` directly, so an unpermitted
      # one would silently stop filtering.
      :released, :rewarding, :from_org,
      sorts: [], id_in: [], name_in: [], kind_in: [], alignment_in: [],
      org_name_in: [], min_standing_in: [], rewarding_in: []
    ]).fetch(:q, {})
  end
end
