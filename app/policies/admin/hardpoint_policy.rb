module Admin
  class HardpointPolicy < BasePolicy
    # The two halves of `hardpoints` have different owners, and only one of them
    # is an admin's to change.
    #
    # `game_files` belongs to the loader: `persist_slot` rewrites those rows on
    # every load, so an edit here would last until the next one and then vanish
    # without a word. That is exactly what made the legacy `model_hardpoints`
    # editor pointless.
    #
    # `ship_matrix` is the curated half -- `persist_loadout` scopes its cleanup
    # to `game_files` precisely so a load cannot reach hand-entered data -- and
    # that is the half this allows.
    #
    # Reading is allowed for both: `index?` and `show?` still alias to `manage?`.
    def update?
      manage? && record.ship_matrix?
    end

    alias_rule :destroy?, to: :update?

    private def resource_access
      [:models]
    end
  end
end
