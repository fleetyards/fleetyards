resources :tours, param: :slug, only: %i[index show create update destroy], constraints: {slug: %r{[^/.]+}} do
  member do
    put :settle
    put :reopen
    put :cancel
    post "rotate-invite", action: :rotate_invite
  end

  collection do
    get "find-by-invite/:token", to: "tours#find_by_invite"
    post "join/:token", to: "tours#join"
  end

  # Creation and lookup are owner-scoped; everything else about a ledger is
  # addressed by ledger id under /payouts.
  get "payouts", to: "payout_ledgers#show_for_subject"
  post "payouts", to: "payout_ledgers#create"
end
