# frozen_string_literal: true

require "test_helper"

class FrontendEnlistPreviewTest < ActionDispatch::IntegrationTest
  setup do
    ViteRuby.instance.stubs(:dev_server_running?).returns(true)
  end

  test "a link to the enlist page previews with its own title and description" do
    get "/enlist/"

    assert_response :success
    assert_includes meta("og:title"), I18n.t("title.frontend.enlist")
    assert_includes meta("og:description"), "50,000 UEC"
  end

  private def meta(property)
    CGI.unescapeHTML(response.body[/<meta property="#{property}" content="([^"]*)"/, 1].to_s)
  end
end
