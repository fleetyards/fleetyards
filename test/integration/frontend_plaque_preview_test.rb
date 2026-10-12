# frozen_string_literal: true

require "test_helper"

# A shared plaque link is the public hangar with the plaque open; a crawler
# reading it has to see the plaque, not the hangar's flagship.
class FrontendPlaquePreviewTest < ActionDispatch::IntegrationTest
  setup do
    ViteRuby.instance.stubs(:dev_server_running?).returns(true)
    Flipper.enable("vehicle_overview")

    @user = create(:user, public_hangar: true)
    @vehicle = create(:vehicle, user: @user, public: true, name: "Contorta", name_visible: true, dedication: "Built rough")
    @vehicle.plaque_image.attach(io: file_fixture("ship.jpg").open, filename: "plaque.jpg", content_type: "image/jpeg")
  end

  test "a shared plaque previews as the plaque" do
    get "/hangar/#{@user.username}/?plaque=#{@vehicle.id}"

    assert_includes meta("og:title"), "Contorta"
    assert_equal "Built rough", meta("og:description")
    assert_includes meta("og:image"), "plaque.jpg"
    assert_includes response.body, '<meta name="twitter:card" content="summary_large_image">'
  end

  test "a hidden ship's plaque previews as the hangar" do
    @vehicle.update!(public: false)

    get "/hangar/#{@user.username}/?plaque=#{@vehicle.id}"

    assert_not_includes meta("og:image"), "plaque.jpg"
    assert_not_includes response.body, "twitter:card"
  end

  test "a plaque that has not been drawn yet previews as the hangar" do
    @vehicle.plaque_image.purge

    get "/hangar/#{@user.username}/?plaque=#{@vehicle.id}"

    assert_not_includes meta("og:title"), "Contorta"
  end

  private def meta(property)
    response.body[/<meta property="#{property}" content="([^"]*)"/, 1].to_s
  end
end
