# frozen_string_literal: true

require "test_helper"

class FrontendManifestTest < ActionDispatch::IntegrationTest
  setup do
    # CI has neither a built Vite manifest nor a dev server; pretending the dev
    # server is up makes every asset lookup resolve to a path instead of raising.
    ViteRuby.instance.stubs(:dev_server_running?).returns(true)
  end

  test "the manifest is valid JSON with what an installable app needs" do
    get "/manifest-digest.json"

    assert_response :success

    manifest = JSON.parse(response.body)

    assert_equal "/", manifest["id"]
    assert_equal "/", manifest["scope"]
    assert_equal "standalone", manifest["display"]
    assert_equal({"client_mode" => "navigate-existing"}, manifest["launch_handler"])
    assert manifest["icons"].any? { |icon| icon["purpose"] == "maskable" }
    assert_equal %w[wide narrow], manifest["screenshots"].pluck("form_factor")
    assert_equal %w[/hangar/ /events/ /compare/], manifest["shortcuts"].pluck("url")
  end
end
