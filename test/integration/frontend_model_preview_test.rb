# frozen_string_literal: true

require "test_helper"

# A ship that is never sold has no store art, so its links preview the coloured
# angled render instead of the default picture.
class FrontendModelPreviewTest < ActionDispatch::IntegrationTest
  setup do
    ViteRuby.instance.stubs(:dev_server_running?).returns(true)

    @model = create(:model)
    @model.angled_view_colored.attach(io: file_fixture("test.png").open, filename: "angled-colored.png", content_type: "image/png")
  end

  %w[images videos].each do |page|
    test "the #{page} page of a ship without gallery images previews its angled render" do
      get "/ships/#{@model.slug}/#{page}"

      assert_includes meta("og:image"), "angled-colored.png"
    end
  end

  test "a comparison of one ship without store art previews its angled render" do
    get "/compare", params: {models: [@model.slug]}

    assert_includes meta("og:image"), "angled-colored.png"
  end

  private def meta(property)
    CGI.unescapeHTML(response.body[/<meta property="#{property}" content="([^"]*)"/, 1].to_s)
  end
end
