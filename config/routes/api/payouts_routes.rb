resources :payout_ledgers, path: "payouts", only: %i[show] do
  member do
    put :settle
    put :reopen
    get :balances
  end

  resources :payout_participants, path: "participants", only: %i[index create destroy]
  resources :payout_entries, path: "entries", only: %i[index create update destroy]

  resources :payout_transfers, path: "transfers", only: %i[index] do
    member do
      put :confirm
      delete :confirm, action: :unconfirm
    end
  end
end
