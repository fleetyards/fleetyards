# frozen_string_literal: true

require "test_helper"

# The plaque tool opens on an example, so a shared link to it previews as that
# example rather than the site's own card.
class FrontendPlaqueToolPreviewTest < ActionDispatch::IntegrationTest
  setup do
    ViteRuby.instance.stubs(:dev_server_running?).returns(true)
  end

  test "a link to the plaque tool previews as the example plaque" do
    get "/tools/plaque/"

    assert_response :success
    assert_includes meta("og:title"), "Dedication Plaques"
    assert_includes meta("og:description"), "The Only Constant"
    assert_includes meta("og:image"), "plaque-tool"
    assert_equal "1200", meta("og:image:width")
    assert_equal "630", meta("og:image:height")
    assert_includes response.body, '<meta name="twitter:card" content="summary_large_image">'
  end

  test "a link to the tool with a ship previews the same" do
    get "/tools/plaque/?model=rsi-constellation-mk-iv-phoenix"

    assert_includes meta("og:image"), "plaque-tool"
  end

  private def meta(property)
    CGI.unescapeHTML(response.body[/<meta property="#{property}" content="([^"]*)"/, 1].to_s)
  end
end
