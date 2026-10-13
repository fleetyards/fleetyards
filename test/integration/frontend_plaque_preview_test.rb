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
    @vehicle.plaque_image.attach(io: file_fixture("test.png").open, filename: "plaque.png", content_type: "image/png")
  end

  test "a shared plaque previews as the plaque" do
    get "/hangar/#{@user.username}/?plaque=#{@vehicle.id}"

    assert_includes meta("og:title"), "Contorta"
    assert_equal "Built rough", meta("og:description")
    assert_includes meta("og:image"), "plaque.png"
    assert_includes response.body, '<meta name="twitter:card" content="summary_large_image">'
  end

  test "a shared plaque's picture carries its size and a description" do
    @vehicle.plaque_image.blob.update!(metadata: {analyzed: true, width: 1200, height: 630})

    get "/hangar/#{@user.username}/?plaque=#{@vehicle.id}"

    assert_equal "1200", meta("og:image:width")
    assert_equal "630", meta("og:image:height")
    assert_equal "Contorta dedication plaque", meta("og:image:alt")
  end

  test "a plaque picture not yet analysed leaves its size out" do
    @vehicle.plaque_image.blob.update!(metadata: {})

    get "/hangar/#{@user.username}/?plaque=#{@vehicle.id}"

    assert_not_includes response.body, "og:image:width"
    assert_equal "Contorta dedication plaque", meta("og:image:alt")
  end

  test "a plaque link by the ship's address previews as the plaque" do
    @vehicle.update!(serial: "L8-4261-HA")

    get "/hangar/#{@user.username}/?plaque=l8-4261-ha-contorta"

    assert_includes meta("og:title"), "Contorta (L8-4261-HA)"
  end

  test "a hidden ship's plaque previews as the hangar" do
    @vehicle.update!(public: false)

    get "/hangar/#{@user.username}/?plaque=#{@vehicle.id}"

    assert_not_includes meta("og:image"), "plaque.png"
    assert_not_includes response.body, "twitter:card"
  end

  test "a plaque that has not been drawn yet still names the ship and its dedication" do
    @vehicle.plaque_image.purge

    get "/hangar/#{@user.username}/?plaque=#{@vehicle.id}"

    assert_includes meta("og:title"), "Contorta"
    assert_equal "Built rough", meta("og:description")
    assert_not_includes meta("og:image"), "plaque.png"
  end

  # Decoded, as a crawler reads it: a Faker name like "O'Hara" sits in the
  # attribute as "O&#39;Hara".
  private def meta(property)
    CGI.unescapeHTML(response.body[/<meta property="#{property}" content="([^"]*)"/, 1].to_s)
  end
end
