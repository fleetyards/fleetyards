# `slug` rather than the id: it comes from the record key, so it is stable, and
# it is the only unique thing a mission has to be found by -- 2536 contracts
# share 836 titles between them.
resources :missions, only: %i[index show], param: :slug, controller: "game_missions"

# The orgs that offer work and the standing bands they offer it in. Built from
# what the loaded catalogue actually carries rather than from a constant: an
# org the export drops should stop being offered as a filter.
namespace :filters do
  resources :missions, only: [], controller: "game_missions" do
    collection do
      get :orgs
      get :standings
      get "reward-kinds", to: "game_missions#reward_kinds"
    end
  end
end
