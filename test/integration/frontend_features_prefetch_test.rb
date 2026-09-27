# frozen_string_literal: true

require "test_helper"

class FrontendFeaturesPrefetchTest < ActionDispatch::IntegrationTest
  setup do
    # CI has neither a built Vite manifest nor a dev server; pretending the dev
    # server is up makes every asset lookup resolve to a path instead of raising.
    ViteRuby.instance.stubs(:dev_server_running?).returns(true)

    @user = create(:user)
    @fleet = create(:fleet)
    create(:fleet_membership, :accepted, fleet: @fleet, user: @user)
  end

  test "the page prefetches the viewer's own flags" do
    Flipper.add("PersonalFeature")
    Flipper.enable_actor("PersonalFeature", @user)
    sign_in @user

    get "/"

    assert_includes prefetched_features, "PersonalFeature"
  end

  # The prefetch seeds the query GET /api/v1/features answers, and a fleet's
  # flags come with that fleet: counted here, they showed up on the pages of
  # every other fleet the viewer is in.
  test "the page leaves a flag enabled only for one of the viewer's fleets out" do
    Flipper.add("FleetWideFeature")
    Flipper.enable_actor("FleetWideFeature", @fleet)
    sign_in @user

    get "/"

    assert_not_includes prefetched_features, "FleetWideFeature"
  end

  private def prefetched_features
    assert_response :success

    prefetch = response.body[/window\.DATA_PREFETCH = (.*)$/, 1]
    features = JSON.parse(prefetch.to_s.chomp(";"))&.dig("features")

    features ? JSON.parse(features) : []
  end
end
