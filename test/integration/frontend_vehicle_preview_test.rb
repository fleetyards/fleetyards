# frozen_string_literal: true

require "test_helper"

# A ship's pages are its owner's, but a link to one gets passed around: the
# server answers it so the preview names the ship where the public hangar would.
class FrontendVehicleRouteTest < ActionDispatch::IntegrationTest
  {
    "/hangar/torlek/l8-4261-ha-contorta" => "vehicle",
    "/hangar/torlek/l8-4261-ha-contorta/overview" => "vehicle",
    "/hangar/torlek/e143180d-44fc-44a6-af11-2c03990b8a30" => "vehicle",
    "/hangar/torlek/e143180d-44fc-44a6-af11-2c03990b8a30-contorta/log" => "vehicle",
    "/hangar/torlek/stats" => "public",
    "/hangar/torlek/fleetchart" => "public",
    "/hangar/torlek/wishlist" => "wishlist"
  }.each do |path, action|
    test "GET #{path} reaches hangar##{action}" do
      recognized = Rails.application.routes.recognize_path(path)

      assert_equal "frontend/hangar", recognized[:controller]
      assert_equal action, recognized[:action]
    end
  end
end

class FrontendVehiclePreviewTest < ActionDispatch::IntegrationTest
  setup do
    ViteRuby.instance.stubs(:dev_server_running?).returns(true)

    @user = create(:user, public_hangar: true)
    @vehicle = create(:vehicle, user: @user, public: true, name: "Contorta", name_visible: true,
      serial: "L8-4261-HA", dedication: "Built rough")
  end

  test "a public ship's page previews as the ship" do
    get "/hangar/#{@user.username}/l8-4261-ha-contorta/overview"

    assert_includes meta("og:title"), "Contorta (L8-4261-HA)"
    assert_equal "Built rough", meta("og:description")
  end

  test "the ship is found by its id as well as its serial" do
    get "/hangar/#{@user.username}/#{@vehicle.id}-contorta"

    assert_includes meta("og:title"), "Contorta"
  end

  test "a ship whose name is hidden previews by its model, without name or serial" do
    @vehicle.update!(name_visible: false)

    get "/hangar/#{@user.username}/l8-4261-ha-contorta"

    assert_not_includes meta("og:title"), "Contorta"
    assert_not_includes meta("og:title"), "L8-4261-HA"
    assert_includes meta("og:title"), @vehicle.model.name
  end

  test "a hidden ship's page says nothing about it" do
    @vehicle.update!(public: false)

    get "/hangar/#{@user.username}/l8-4261-ha-contorta"

    assert_not_includes response.body, "Contorta"
    assert_not_includes response.body, "Built rough"
  end

  test "a private hangar's ship stays unnamed" do
    @user.update!(public_hangar: false)

    get "/hangar/#{@user.username}/l8-4261-ha-contorta"

    assert_not_includes meta("og:title"), "Contorta"
  end

  private def meta(property)
    response.body[/<meta property="#{property}" content="([^"]*)"/, 1].to_s
  end
end
