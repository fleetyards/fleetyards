# `slug` comes from the record key, so a mission can link to its faction from
# `org_key` alone.
resources :factions, only: %i[index show], param: :slug
